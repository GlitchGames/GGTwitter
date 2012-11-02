GGTwitter
============

GGTwitter makes it very easy to authorise your player with Twitter and post messages. 
Authorisation data is stored so that the user only has to login the first time.

oAuth.lua from here - https://github.com/breinhart/Corona-SDK-Tweet-Media/blob/master/utils/oAuth.lua
multipartForm.lua from here - https://github.com/breinhart/Corona-SDK-Tweet-Media/blob/master/utils/multipartForm.lua

Basic Usage
-------------------------

##### Require the code
```lua
local GGTwitter = require( "GGTwitter" )
```

##### Create your Twitter object passing in your apps consumerKey, consumerSecret and optional listener
```lua
local twitter

local listener = function( event )
	if event.phase == "authorised" then
		
	end
end

twitter = GGTwitter:new( "XXXXXXXXXXXXXXXXXXXX", "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", listener )
```

##### Authorise twitter
```lua
twitter:authorise()
```

##### Tweet a message
```lua
twitter:post( "Hello, world!" )
```

##### Tweet a message with an image
```lua
twitter:post( "Check out my photo!", "image.png" )
```

##### Check if the user is authorised.
```lua
print( twitter:isAuthorised() )
```

##### Follow a user.
```lua
twitter:follow( "GlitchGames" )
```

##### Deauthorise the user
```lua
twitter:deauthorise()
```

##### Destroy the Twitter object
```lua
twitter:destroy()
twitter = nil
```

Update History
-------------------------

##### 0.1
Initial release