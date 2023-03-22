use path::Path;
use std::collections::HashMap;
use std::ffi::OsStr;
use std::time::Duration;
use std::{error, io, path, result};
use url::Url;

use lol_html::{element, rewrite_str, RewriteStrSettings};

pub type Result<T> = result::Result<T, Box<dyn error::Error>>;

const IMAGE_SIZE_LIMIT: usize = 1_024 * 1_024; // 1 MB
const MEDIA_TYPES: &str = include_str!("media-types.txt");

#[derive(Debug)]
pub struct Image {
    pub url: Url,
    pub path: String,
}

impl Image {
    fn build(img_src: &str, chapter: usize) -> Result<Image> {
        let mut url = Url::parse(img_src)?;

        url.set_query(None);

        let image = Path::new(url.path())
            .file_name()
            .and_then(OsStr::to_str)
            .ok_or("image file name is invalid")?;

        let path = format!("chapter_{}/{}", chapter, image);

        Ok(Image { url, path })
    }

    pub fn mime_type(&self) -> &str {
        media_type_from_path(&self.path).unwrap_or("application/octet-stream")
    }
}

pub fn rewrite_images(html: &str, chapter: usize) -> Result<(String, Vec<Image>)> {
    let mut images = HashMap::new();

    let element_content_handlers = vec![element!("img[src]", |el| {
        let img_src = el.get_attribute("src").expect("img[src] was required");

        let image: &Result<Image> = images
            .entry(img_src)
            .or_insert_with_key(|k| Image::build(k, chapter));

        match image {
            Ok(image) => {
                el.remove_attribute("loading");
                el.remove_attribute("srcset");
                el.set_attribute("src", &image.path)?;
            }
            Err(e) => {
                eprintln!(
                    "Failed to build Image from img[src], skipping image, error={}",
                    e
                );
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

pub fn download_image(
    image: &Image,
) -> result::Result<Vec<u8>, Box<dyn error::Error + Send + Sync + 'static>> {
    use std::io::Read;

    let resp = ureq::get(image.url.as_str())
        .timeout(Duration::from_secs(5))
        .call()?;

    let len: usize = resp
        .header("Content-Length")
        .unwrap_or_default()
        .parse()
        .unwrap_or_default();

    let mut buf: Vec<u8> = Vec::with_capacity(len);

    resp.into_reader()
        .take((IMAGE_SIZE_LIMIT + 1) as u64)
        .read_to_end(&mut buf)?;

    if buf.len() > IMAGE_SIZE_LIMIT {
        return Err(io::Error::new(io::ErrorKind::Other, "image size is too large").into());
    }

    Ok(buf)
}

// TODO: maybe use a templating library
pub fn gen_xhtml(title: &str, content: String) -> String {
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

fn media_type_from_path(path: &str) -> Option<&str> {
    let extension = Path::new(path).extension().and_then(OsStr::to_str)?;

    MEDIA_TYPES.lines().find_map(|l| {
        let (ext, mime) = l.split_once(',').unwrap();

        (extension == ext).then_some(mime)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn media_types() {
        let mime_type = media_type_from_path("hello.png");
        assert_eq!(mime_type, Some("image/png"));

        let mime_type = media_type_from_path("hello.jpg");
        assert_eq!(mime_type, Some("image/jpeg"));
    }
}
