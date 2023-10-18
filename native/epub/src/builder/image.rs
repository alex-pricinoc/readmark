use std::cmp::min;
use std::fmt::Display;
use std::io::{Cursor, Read};
use std::time::Duration;
use std::{collections::HashMap, fmt::Debug};

use image::ImageOutputFormat;
use lol_html::{element, rewrite_str, RewriteStrSettings};
use once_cell::sync::Lazy;
use url::Url;

static AGENT: Lazy<ureq::Agent> =
    Lazy::new(|| ureq::builder().timeout(Duration::from_secs(5)).build());

type Result<T> = std::result::Result<T, Box<dyn std::error::Error + Send + Sync + 'static>>;

#[derive(Debug)]
pub struct Image {
    url: Url,
    pub path: String,
}

impl Image {
    fn build(img_src: &str, path: String) -> Result<Image> {
        let mut url = Url::parse(img_src).map_err(|e| format!("{}: {}", e, img_src))?;

        if !url.has_host() {
            Err(format!("URL has no host: {}", img_src))?;
        }

        url.set_query(None);

        Ok(Image { url, path })
    }

    pub fn download(&self) -> Result<Vec<u8>> {
        const MAX_SIZE: usize = 10e6 as _;

        let res = AGENT.get(self.url.as_str()).call()?;

        if res.status() != 200 {
            Err(format!("{}: {}", res.status(), res.status_text()))?;
        }

        let len = res
            .header("Content-Length")
            .and_then(|s| s.parse().ok())
            .unwrap_or_default();

        let mut bytes = Vec::with_capacity(min(len, MAX_SIZE));

        res.into_reader()
            .take(MAX_SIZE as _)
            .read_to_end(&mut bytes)?;

        let image = image::load_from_memory(&bytes)?
            .grayscale()
            .thumbnail(700, 700);

        let mut bytes = Vec::new();

        image.write_to(&mut Cursor::new(&mut bytes), ImageOutputFormat::Jpeg(80))?;

        Ok(bytes)
    }
}

pub fn rewrite_images(
    html: &mut String,
    chapter: impl Display + Copy,
) -> Result<impl IntoIterator<Item = Result<Image>>> {
    let mut images = HashMap::new();
    let mut index = 0;

    let element_content_handlers = vec![element!("img", |el| {
        let Some(img_src) = el.get_attribute("src").or(el.get_attribute("data-src")) else {
            log::warn!("could not get img[src] of: {el:?}");

            return Ok(());
        };

        index += 1;

        let image = images
            .entry(img_src)
            .or_insert_with_key(|k| Image::build(k, format!("ch_{chapter}/img-{index}.jpg")));

        if let Ok(img) = image {
            el.remove_attribute("loading");
            el.remove_attribute("srcset");
            el.set_attribute("src", &img.path)?;
        }

        Ok(())
    })];

    *html = rewrite_str(
        html,
        RewriteStrSettings {
            element_content_handlers,
            ..RewriteStrSettings::default()
        },
    )?;

    let images = images.into_values();

    Ok(images)
}
