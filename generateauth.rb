##########
# USED TO CREATE yaml FILE WITH ACCESS TOKEN INFO
#
# replace with account consumer key and consumer secret:
CONSUMER_KEY = 'XXXXXXXXXX'
CONSUMER_SECRET = 'XXXXXXXXXX'

auth={}
auth["consumer_key"] = CONSUMER_KEY
auth["consumer_secret"] = CONSUMER_SECRET

@consumer=OAuth::Consumer.new auth["consumer_key"],
                              auth["consumer_secret"],
                              {:site=>"https://api.500px.com",
                                  :request_token_path => "/v1/oauth/request_token",
                                  :access_token_path  => "/v1/oauth/access_token",
                                  :authorize_path     => "/v1/oauth/authorize"}

@request_token = @consumer.get_request_token

puts "Visit the following URL, log in if you need to, and authorize the app"
puts @request_token.authorize_url

verifier = gets.strip

@access_token = @request_token.get_access_token(:oauth_verifier => verifier)

auth["token"] = @access_token.token
auth["token_secret"] = @access_token.secret

File.open('auth.yaml', 'w') {|f| YAML.dump(auth, f)}
