use std::fmt::Display;
use std::io::Cursor;
use std::{collections::HashMap, fmt::Debug};

use image::ImageOutputFormat;
use lol_html::{element, rewrite_str, RewriteStrSettings};
use once_cell::sync::Lazy;
use url::Url;

pub type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

static AGENT: Lazy<ureq::Agent> = Lazy::new(|| ureq::builder().build());

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

    pub fn download(&self) -> Result<Vec<u8>> {
        let res = AGENT.get(self.url.as_str()).call()?;

        if res.status() != 200 {
            return Err(format!("{} {}", res.status(), res.status_text()).into());
        }

        let len = res
            .header("Content-Length")
            .and_then(|s| s.parse().ok())
            .unwrap_or_default();

        let mut bytes = Vec::with_capacity(len);

        res.into_reader().read_to_end(&mut bytes)?;

        let image = image::load_from_memory(&bytes)?
            .grayscale()
            .thumbnail(700, 700);

        let mut bytes = Vec::new();

        image.write_to(&mut Cursor::new(&mut bytes), ImageOutputFormat::Jpeg(80))?;

        Ok(bytes)
    }
}

pub fn rewrite_images(html: &str, chapter: impl Display + Copy) -> Result<(String, Vec<Image>)> {
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
