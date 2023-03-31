use std::{fs::File, path::Path};

mod builder;

use builder::{Builder, Item};

use rustler::{Error, ListIterator, NifResult, NifStruct};

#[derive(Debug, NifStruct)]
#[module = "Readmark.Bookmarks.Article"]
pub struct Article {
    url: String,
    title: String,
    article_html: String,
}

#[derive(Debug, NifStruct)]
#[module = "Epub.Native.EpubOptions"]
pub struct EpubOptions {
    title: String,
    dir: String,
}

impl From<Article> for Item {
    fn from(article: Article) -> Item {
        Item {
            title: article.title,
            content: article.article_html,
        }
    }
}

#[rustler::nif(schedule = "DirtyIo")]
fn build(iter: ListIterator, options: EpubOptions) -> NifResult<String> {
    let path = Path::new(&options.dir);

    let epub_path = path
        .join(format!("{}.epub", options.title))
        .into_os_string()
        .into_string()
        .expect("must be a valid path");

    let epub = File::create(&epub_path).unwrap();

    let articles = iter.map(|a| a.decode::<Article>().unwrap().into());

    Builder::new("readmark", epub)
        .run(articles)
        .map_err(|e| Error::Term(Box::new(e.to_string())))?;

    Ok(epub_path)
}

rustler::init!("Elixir.Epub.Native", [build]);
