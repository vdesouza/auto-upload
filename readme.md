# Auto upload tool for 500px

A ruby script to automate photo uploads to a personal account on 500px.com.

`generateauth.rb` will generate a yaml file with oauth credentials that the script will use. Requires a user's consumer_key and consumer_secret.

`autoupload.rb` uses the generated yaml file to authenticate user using API calls from 500px.com. Script takes in as arguments file paths to images wanting to be uploaded. Script also requires [mini_exiftool](https://github.com/janfri/mini_exiftool) ruby gem installed.

Script uses mini_exiftool to generate:
- photo name
- photo description
- camera settings such as shutter speed, focal length, aperture, iso, camera model, camera make, and lens used
- tags

The information should be saved in the metadata of the photograph.

Future todos:
- add error handling for when upload cannot be completed such as reaching weekly upload limit.
