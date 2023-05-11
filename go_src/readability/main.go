package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/go-shiori/go-readability"
)

type Article struct {
	Url         string `json:"url"`
	Title       string `json:"title"`
	Content     string `json:"article_html"`
	TextContent string `json:"article_text"`
	Excerpt     string `json:"excerpt"`
	Length      int    `json:"length"`
}

func init() {
	log.SetFlags(0)
}

func main() {
	args := os.Args[1:]

	if len(args) != 1 {
		log.Fatal("must provide a url")
	}

	article, err := readability.FromURL(args[0], 10*time.Second)

	if err != nil {
		log.Fatal(err)
	}

	res := Article{
		Url:         args[0],
		Title:       article.Title,
		Excerpt:     article.Excerpt,
		Length:      article.Length,
		Content:     article.Content,
		TextContent: article.TextContent,
	}

	json, err := json.Marshal(&res)

	if err != nil {
		log.Fatal("unable to encode json")
	}

	fmt.Print(string(json))
}
