package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/go-shiori/go-readability"
)

type Article struct {
	Url         string `json:"url"`
	Title       string `json:"title"`
	Excerpt     string `json:"excerpt"`
	Length      int    `json:"length"`
	Content     string `json:"content"`
	TextContent string `json:"text_content"`
}

func main() {
	args := os.Args[1:]

	if len(args) != 1 {
		die("must provide a url")
	}

	article, err := readability.FromURL(args[0], 5*time.Second)

	if err != nil {
		die(err.Error())
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
		die("unable to encode json")
	}

	fmt.Print(string(json))
}

func die(msg string) {
	fmt.Print(msg)
	os.Exit(1)
}
