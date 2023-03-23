use std::{ffi::OsStr, path::Path};

include!("mime_types.rs");

pub struct MimeGuess(&'static str);

impl MimeGuess {
    pub fn get_or_default(&self) -> &str {
        if self.0.is_empty() {
            "application/octet-stream"
        } else {
            self.0
        }
    }

    pub fn from_ext(ext: &str) -> Self {
        get_mime_types(ext).map_or(MimeGuess(""), MimeGuess)
    }

    pub fn from_path<P: AsRef<Path>>(path: P) -> Self {
        path.as_ref()
            .extension()
            .and_then(OsStr::to_str)
            .map_or(MimeGuess(""), Self::from_ext)
    }
}

fn get_mime_types(ext: &str) -> Option<&'static str> {
    map_lookup(MIME_TYPES, ext)
}

fn map_lookup<K, V>(map: &'static [(K, V)], key: &str) -> Option<V>
where
    K: Copy + Into<&'static str>,
    V: Copy,
{
    map.binary_search_by_key(&key, |(k, _)| (*k).into())
        .ok()
        .map(|i| map[i].1)
}

#[cfg(test)]
mod tests {

    include!("mime_types.rs");

    use super::*;

    #[test]
    fn test_are_extensions_sorted() {
        // simultaneously checks the requirement that duplicate extension entries are adjacent
        for (&ext, &n_ext) in MIME_TYPES.iter().zip(MIME_TYPES.iter().skip(1)) {
            assert!(
                ext <= n_ext,
                "Extensions in src/mime_types should be sorted lexicographically
            in ascending order. Failed assert: {:?} <= {:?}",
                ext,
                n_ext
            );
        }
    }

    #[test]
    fn test_mime_type_guessing() {
        assert_eq!(
            MimeGuess::from_ext("gif").get_or_default().to_string(),
            "image/gif".to_string()
        );
        assert_eq!(
            MimeGuess::from_ext("txt").get_or_default().to_string(),
            "text/plain".to_string()
        );
        assert_eq!(
            MimeGuess::from_ext("blahblah").get_or_default().to_string(),
            "application/octet-stream".to_string()
        );

        assert_eq!(
            MimeGuess::from_path(Path::new("/path/to/file.gif"))
                .get_or_default()
                .to_string(),
            "image/gif".to_string()
        );
        assert_eq!(
            MimeGuess::from_path("/path/to/file.gif")
                .get_or_default()
                .to_string(),
            "image/gif".to_string()
        );
    }

    #[test]
    fn test_mime_type_guessing_opt() {
        assert_eq!(
            MimeGuess::from_ext("gif").get_or_default().to_string(),
            "image/gif".to_string()
        );
        assert_eq!(
            MimeGuess::from_ext("txt").get_or_default().to_string(),
            "text/plain".to_string()
        );
        assert_eq!(MimeGuess::from_ext("blah").0, "");

        assert_eq!(
            MimeGuess::from_path("/path/to/file.gif")
                .get_or_default()
                .to_string(),
            "image/gif".to_string()
        );
        assert_eq!(MimeGuess::from_path("/path/to/file").0, "");
    }
}
