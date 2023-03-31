mod mime_guess;
mod utils;

use std::{io, sync::mpsc};

use utils::{Image, Result};

use epub_builder::{EpubBuilder, EpubContent, EpubVersion, ReferenceType, ZipLibrary};
use rayon::ThreadPoolBuilder;

pub struct Builder<W> {
    title: &'static str,
    out: W,
    epub: EpubBuilder<ZipLibrary>,
}

pub struct Item {
    pub title: String,
    pub content: String,
}

const STYLE: &str =
    "body { margin: 0; padding: 0; line-height: 1.2; } img { width: 100%; height: auto; }";

impl<W: io::Write> Builder<W> {
    pub fn new(title: &'static str, out: W) -> Self
    where
        W: io::Write,
    {
        Self {
            title,
            out,
            epub: EpubBuilder::new(ZipLibrary::new().unwrap()).unwrap(),
        }
    }

    pub fn run(&mut self, items: impl Iterator<Item = Item>) -> Result<()> {
        self.make_book()?;

        let mut all_images: Vec<Image> = vec![];

        for (index, mut item) in items.enumerate() {
            let (content, mut images) = utils::rewrite_images(index, &item.content)?;
            item.content = content;
            all_images.append(&mut images);

            self.add_content(index, item)?;
        }

        self.embed_images(all_images)?;

        self.epub.generate(self.out.by_ref())?;

        Ok(())
    }

    fn make_book(&mut self) -> Result<()> {
        self.epub
            .metadata("title", format!("readmark: {}", self.title))?
            .metadata("author", "readmark")?
            .epub_version(EpubVersion::V30)
            // TODO: each chapter is shown twice when using inline_toc and EpubVersion::V30
            // .inline_toc()
            .stylesheet(STYLE.as_bytes())?;

        Ok(())
    }

    fn embed_images(&mut self, images: Vec<Image>) -> Result<()> {
        let pool = ThreadPoolBuilder::new().num_threads(4).build()?;

        let (sender, receiver) = mpsc::channel();

        for image in images {
            let sender = sender.clone();

            pool.spawn(move || {
                let result = utils::download_image(&image);

                sender.send((image, result)).unwrap();
            })
        }

        drop(sender);

        for (image, result) in receiver {
            match result {
                Ok(content) => {
                    self.epub
                        .add_resource(&image.path, content.as_slice(), &image.mime)?;
                }
                Err(e) => {
                    eprintln!("Error fetching url: {}", e);

                    continue;
                }
            }
        }

        Ok(())
    }

    fn add_content(&mut self, index: usize, Item { title, content, .. }: Item) -> Result<()> {
        let content = utils::gen_xhtml(&title, content);

        let mut chapter =
            EpubContent::new(format!("chapter_{}.xhtml", index), content.as_bytes()).title(title);

        if index == 0 {
            chapter = chapter.reftype(ReferenceType::Text);
        }

        self.epub.add_content(chapter)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn builder() -> Builder<Vec<u8>> {
        Builder::new("test", vec![])
    }

    #[test]
    fn test_builder() {
        let item = Item {
            title: "test title".into(),
            content: r#"<p>Test content</p>"#.into(),
        };

        let res = builder().run([item].into_iter());

        assert!(res.is_ok());
    }
}
