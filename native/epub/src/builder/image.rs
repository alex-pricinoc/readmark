use std::collections::HashMap;
use std::io::Cursor;
use std::{error, result};

use lol_html::{element, rewrite_str, RewriteStrSettings};
use mime::Mime;
use url::Url;

pub type Result<T> = result::Result<T, Box<dyn error::Error>>;

#[derive(Debug)]
pub struct Image {
    pub url: Url,
    pub path: String,
    pub mime: Option<Mime>,
    bytes: Option<Vec<u8>>,
}

impl Image {
    fn build(img_src: &str, path: String) -> Result<Image> {
        let mut url = Url::parse(img_src)?;
        url.set_query(None);

        Ok(Image {
            url,
            path,
            mime: None,
            bytes: None,
        })
    }

    pub fn download(&mut self) -> Result<()> {
        match minreq::get(self.url.as_str()).send() {
            Ok(mut res) if res.status_code == 200 => {
                let mime = res
                    .headers
                    .remove("content-type")
                    .and_then(|m| m.parse::<Mime>().ok())
                    .or_else(|| mime_guess::from_path(self.url.path()).first());

                self.mime = mime;
                self.bytes = Some(res.into_bytes());

                Ok(())
            }
            // TODO: handle redirects
            Ok(res) => {
                let status = res.status_code;
                let reason = res.reason_phrase;

                let err = format!("{} ({})", status, reason);

                Err(err.into())
            }
            Err(err) => Err(err.into()),
        }
    }

    pub fn compress(&mut self) -> Result<()> {
        let buffer = self.bytes.as_ref().ok_or("empty image")?.as_slice();

        let image_format = self
            .mime
            .as_ref()
            .and_then(image::ImageFormat::from_mime_type);

        let image = match image_format {
            Some(format) => image::load_from_memory_with_format(buffer, format)?,
            None => image::load_from_memory(buffer)?,
        };

        let image = image.grayscale().thumbnail(500, 500);

        let mut bytes: Vec<u8> = vec![];

        image.write_to(
            &mut Cursor::new(&mut bytes),
            image::ImageOutputFormat::Jpeg(80),
        )?;

        self.bytes.replace(bytes);

        Ok(())
    }

    pub fn content(&self) -> Option<&[u8]> {
        self.bytes.as_deref()
    }
}

pub fn rewrite_images(chapter: usize, html: &str) -> Result<(String, Vec<Image>)> {
    let mut images = HashMap::new();
    let mut index = 0;

    let element_content_handlers = vec![element!("img[src]", |el| {
        let img_src = el.get_attribute("src").expect("img[src] is required");

        index += 1;

        let image = images
            .entry(img_src)
            .or_insert_with_key(|k| Image::build(k, format!("ch_{chapter}/img-{index}.jpg")));

        match image {
            Ok(image) => {
                el.remove_attribute("loading");
                el.remove_attribute("srcset");
                el.set_attribute("src", &image.path)?;
            }
            Err(e) => {
                eprintln!("Failed to parse Image, skipping image: {}", e);
            }
        }

        Ok(())
    })];

    let output = rewrite_str(
        html,
        RewriteStrSettings {
            element_content_handlers,
            ..RewriteStrSettings::default()
        },
    )?;

    let images = images.into_values().flatten().collect();

    Ok((output, images))
}
