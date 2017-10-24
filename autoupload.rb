require 'rubygems'
require 'oauth'
require 'yaml'
require 'json'
require 'uri'
require 'net/https'
require 'net/http/post/multipart'
require 'openssl'
require 'mini_exiftool'

BASE_URL = "https://api.500px.com"
PHOTO_UPLOAD_ENDPOINT = "/v1/photos/upload"

if ARGV.size < 1
  puts "Usage: #{$0} path_to_img_file"
  puts "e.g. #{$0} /Desktop/picture.jpg"
  exit(1)
end

auth = YAML.load(File.open('auth.yaml'))

@consumer=OAuth::Consumer.new auth["consumer_key"],
                              auth["consumer_secret"],
                              {:site=>BASE_URL,
                                  :request_token_path => "/v1/oauth/request_token",
                                  :access_token_path  => "/v1/oauth/access_token",
                                  :authorize_path     => "/v1/oauth/authorize"}

@access_token = OAuth::AccessToken.new(@consumer, auth['token'], auth['token_secret'])


# Uses the OAuth gem to add the signed Authorization header
def add_oauth(req)
  @consumer.sign!(req, @access_token)
end

# 500px: Uploading photos parameters
# file - file name
# name - title of photo
# description - description of photo
# category - number representing category (leave at 0)
# privacy - 0 is public, 1 is private
# shutter_speed - string containing a rational expression if the value is <1 sec., or a decimal value if the value is >1sec
# focal_length — Focal length in millimetres, a string representing an integer value
# aperture — Aperture value
# iso — ISO value
# camera — Make and model of the camera
# lens — Lens used to make this photo
# tags - comma separated list of tags

def get_file_params(file)
    exif = MiniExiftool.new(file)
    params = {}
    params["file_name"] = file.match(/\/.+\/(.+)\.jpg$/).captures.first
    params["name"] = exif['ObjectName'].gsub(' ', '%20')
    params["description"] = exif['Description'].gsub(' ', '%20')
    params["category"] = 0
    params["privacy"] = 1
    params["shutter_speed"] = exif['ShutterSpeed']
    params["focal_length"] = exif['FocalLength'].gsub(' mm', '')
    params["aperture"] = exif['Aperture']
    params["iso"] = exif['ISO']
    params["camera"] = (exif['Make'] + ' ' + exif['Model']).gsub(' ', '%20')
    params["lens"] = exif['LensModel'].gsub(' ', '%20')
    params["tags"] = exif['Keywords'].join(',').gsub(' ', '%20')

    return params
end

# Uploads a photo to account
def upload_photo(file, params)
    url_str = BASE_URL + PHOTO_UPLOAD_ENDPOINT + "?"
    # build out url based on params of photo
    url_str = url_str + "name=#{params['name']}&description=#{params['description']}&category=0&privacy=0"

    url = URI.parse(url_str)
    File.open(file) do |jpg|
        req = Net::HTTP::Post::Multipart.new url.path, "file" => UploadIO.new(jpg, "image/jpeg", "#{params['file_name']}.jpg")
        add_oauth(req)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.start do |https|
            res = https.request(req)
            # puts res.body
            return res.body
        end
    end
end

def add_photo_params(res, params)
    resjson = JSON.parse(res)
    photo_id = resjson['photo']['id']
    @access_token.put("/v1/photos/#{photo_id}?name=#{params['name']}&description=#{params['description']}&category=0&privacy=0&shutter_speed=#{params['shutter_speed']}&focal_length=#{params['focal_length']}&aperture=#{params['aperture']}&iso=#{params['iso']}&camera=#{params['camera']}&lens=#{params['lens']}&add_tags=#{params['tags']}")
end

# for each file path in ARGV, upload that image.
ARGV.each { |file|
    file_params = get_file_params(file)
    res = upload_photo(file, file_params)
    add_photo_params(res, file_params)
}
