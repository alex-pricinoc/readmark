mod image;

use self::image::Image;
use std::{io, sync::mpsc};

use epub_builder::{EpubBuilder, EpubContent, EpubVersion, ReferenceType, Result, ZipLibrary};
use rayon::ThreadPoolBuilder;

pub struct Builder<W> {
    title: String,
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
    pub fn new(title: String, out: W) -> Self {
        Self {
            title,
            out,
            epub: EpubBuilder::new(ZipLibrary::new().unwrap()).unwrap(),
        }
    }

    pub fn run(&mut self, items: impl Iterator<Item = Item>) -> Result<()> {
        self.make_book()?;

        let mut all_images = vec![];

        for (index, mut item) in items.enumerate() {
            match image::rewrite_images(index, &item.content) {
                Ok((content, mut images)) => {
                    item.content = content;
                    all_images.append(&mut images);
                }
                Err(err) => {
                    eprintln!("Error rewriting images: {}", err);
                }
            }

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
        let pool = ThreadPoolBuilder::new().num_threads(4).build().unwrap();

        let (sender, receiver) = mpsc::channel();

        for mut image in images {
            let sender = sender.clone();

            pool.spawn(move || {
                if let Err(err) = image.download() {
                    eprintln!("Error downloading image: {}", err);
                } else {
                    if let Err(err) = image.compress() {
                        eprintln!("Error compressing image: {}", err);
                    }

                    let mime_type = image
                        .mime
                        .take()
                        .unwrap_or(mime::APPLICATION_OCTET_STREAM)
                        .to_string();

                    sender.send((image, mime_type)).unwrap();
                }
            });
        }

        drop(sender);

        for (image, mime_type) in receiver {
            let content = image.content().expect("image content is empty");

            if let Err(err) = self.epub.add_resource(&image.path, content, mime_type) {
                eprintln!("Error embedding image: {}", err);
            }
        }

        Ok(())
    }

    fn add_content(&mut self, index: usize, Item { title, content }: Item) -> Result<()> {
        let content = Self::gen_xhtml(&title, content);

        let mut chapter =
            EpubContent::new(format!("chapter_{}.xhtml", index), content.as_bytes()).title(title);

        if index == 0 {
            chapter = chapter.reftype(ReferenceType::Text);
        }

        self.epub.add_content(chapter)?;

        Ok(())
    }

    fn gen_xhtml(title: &str, content: String) -> String {
        format!(
            r#"<!DOCTYPE html>
          <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
          <head>
            <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
            <title>{title}</title>
            <link rel="stylesheet" type="text/css" href="stylesheet.css" />
          </head>
          <body>
            <h1>{title}</h1>
            {content}
          </body>
          </html>
          "#
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn builder() -> Builder<Vec<u8>> {
        Builder::new("test".into(), vec![])
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
