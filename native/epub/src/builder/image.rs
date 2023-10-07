use std::collections::HashMap;
use std::io::Cursor;

use image::ImageOutputFormat;
use lol_html::{element, rewrite_str, RewriteStrSettings};
use url::Url;

pub type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

#[derive(Debug)]
pub struct Image {
    url: Url,
    pub path: String,
}

impl Image {
    fn build(img_src: &str, path: String) -> Result<Image> {
        let mut url = Url::parse(img_src)?;
        url.set_query(None);

        Ok(Image { url, path })
    }

    pub fn download(&mut self) -> Result<Vec<u8>> {
        let res = ureq::get(self.url.as_str()).call()?;

        if res.status() != 200 {
            return Err(format!("{} {}", res.status(), res.status_text()).into());
        }

        let mime = res
            .header("Content-Type")
            .and_then(|m| m.parse().ok())
            .or_else(|| mime_guess::from_path(self.url.path()).first());

        let len = res
            .header("Content-Length")
            .and_then(|s| s.parse().ok())
            .unwrap_or_default();

        let mut bytes = Vec::with_capacity(len);

        res.into_reader().read_to_end(&mut bytes)?;

        let image = match mime.and_then(image::ImageFormat::from_mime_type) {
            Some(format) => image::load_from_memory_with_format(&bytes, format)?,
            None => image::load_from_memory(&bytes)?,
        };

        let image = image.grayscale().thumbnail(600, 600);

        let mut bytes = Vec::new();

        image.write_to(&mut Cursor::new(&mut bytes), ImageOutputFormat::Jpeg(80))?;

        Ok(bytes)
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
            Ok(img) => {
                el.remove_attribute("loading");
                el.remove_attribute("srcset");
                el.set_attribute("src", &img.path)?;
            }
            Err(err) => {
                eprintln!("Failed to parse Image, skipping: {}", err);
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
