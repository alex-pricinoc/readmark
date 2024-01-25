mod image;

use self::image::Image;
use epub_builder::{EpubBuilder, EpubContent, EpubVersion, ReferenceType, Result, ZipLibrary};
use rayon::prelude::*;
use std::{io, sync::mpsc, thread};

pub struct Builder<W> {
    out: W,
    title: String,
    epub: EpubBuilder<ZipLibrary>,
}

pub struct Item {
    pub title: String,
    pub content: String,
}

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

        let mut images = vec![];

        for (index, mut item) in items.enumerate() {
            match image::rewrite_images(&mut item.content, index) {
                Ok(imgs) => images.extend(imgs),
                Err(err) => log::error!("error rewriting images: {err}"),
            }

            self.add_content(index, item)?;
        }

        self.embed_images(images);

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
            .stylesheet(
                "body { margin: 0; padding: 0; } img { width: 100%; height: auto; }".as_bytes(),
            )?;

        Ok(())
    }

    fn embed_images(&mut self, images: Vec<Image>) {
        let (sender, receiver) = mpsc::channel();

        thread::spawn(move || {
            images
                .into_par_iter()
                .for_each_with(sender, |sender, mut image| match image.download() {
                    Ok(_) => sender.send(image).unwrap(),
                    Err(err) => log::warn!("error downloading image: {err}"),
                });
        });

        for image in receiver {
            if let Err(err) =
                self.epub
                    .add_resource(image.path, image.bytes.unwrap().as_slice(), "image/jpeg")
            {
                log::error!("error embedding image: {err}");
            }
        }
    }

    fn add_content(&mut self, index: usize, item: Item) -> Result<()> {
        let content = to_xhtml(&item.title, &item.content);

        let mut chapter =
            EpubContent::new(format!("ch_{index}.xhtml"), content.as_bytes()).title(item.title);

        if index == 0 {
            chapter = chapter.reftype(ReferenceType::Text);
        }

        self.epub.add_content(chapter)?;

        Ok(())
    }
}

fn to_xhtml(title: &str, content: &str) -> String {
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
        "#,
    )
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
