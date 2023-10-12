mod builder;

use builder::{Builder, Item};

use rustler::{Error, ListIterator, NifResult as Result, NifStruct};

#[derive(Debug, NifStruct)]
#[module = "Readmark.Bookmarks.Article"]
pub struct Article {
    url: String,
    title: String,
    article_html: String,
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
fn build(title: String, iter: ListIterator) -> Result<Vec<u8>> {
    let articles = iter.map(|a| a.decode::<Article>().unwrap().into());

    let mut epub = Vec::new();

    Builder::new(title, &mut epub)
        .run(articles)
        .map_err(|e| Error::Term(Box::new(e.to_string())))?;

    println!("Generated epub with size: {}Ki", epub.len() / 1024);

    Ok(epub)
}

rustler::init!("Elixir.Epub.Native", [build]);
