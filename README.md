# ElmMusic
A Synthesizer implemented in Elm using Tone.js.

The following steps are performed in the command line.
First, clone the directory and install npm:

`npm install`.

If this doesn't work, you may need to run

`npm init -y`.

Then make using the command:

`elm make src/ElmAndTone.elm --output elm-comp.js` (We do not have a `Main.elm` file; that has been replaced by `ElmAndTone.elm`).

Then run a server in the same directory as index.html. I like to use http-server. To install using npm, run:

`npm install http-server`

Start the server: 

`http-server` 

and visit the local link provided. We recommend using Firefox or Chrome.
