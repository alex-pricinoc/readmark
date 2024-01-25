mod builder;

use builder::{Builder, Item};
use env_logger::Builder as LoggerBuilder;
use log::LevelFilter;
use rustler::{Env, Error, ListIterator, NifResult as Result, NifStruct, Term};

#[derive(Debug, NifStruct)]
#[module = "Readmark.Bookmarks.Article"]
pub struct Article {
    url: String,
    title: String,
    article_html: String,
}

impl From<Article> for Item {
    fn from(article: Article) -> Self {
        Self {
            title: article.title,
            content: article.article_html,
        }
    }
}

fn load(_: Env, _: Term) -> bool {
    LoggerBuilder::new().filter_level(LevelFilter::Info).init();

    true
}

#[rustler::nif(schedule = "DirtyIo")]
fn build(title: String, iter: ListIterator) -> Result<Vec<u8>> {
    let articles = iter.map(|a| a.decode::<Article>().unwrap().into());

    let mut epub = vec![];

    Builder::new(title, &mut epub)
        .run(articles)
        .map_err(|e| Error::Term(Box::new(e.to_string())))?;

    log::info!("Generated epub with size: {}Ki", epub.len() / 1024);

    Ok(epub)
}

rustler::init!("Elixir.Epub.Native", [build], load = load);
