-- Project: GGTwitter
--
-- Date: October 30, 2012
--
-- Version: 0.1
--
-- File name: GGTwitter.lua
--
-- Author: Graham Ranson of Glitch Games - www.glitchgames.co.uk
--
-- Update History:
--
-- 0.1 - Initial release
--
-- Comments: 
-- 
--		GGTwitter makes it very easy to authorise your player with Twitter and post messages. 
--		Authorisation data is stored so that the user only has to login the first time.
--
-- Requirements: 
--
--		oAuth.lua from here - https://github.com/breinhart/Corona-SDK-Tweet-Media/blob/master/utils/oAuth.lua
--		multipartForm.lua from here - https://github.com/breinhart/Corona-SDK-Tweet-Media/blob/master/utils/multipartForm.lua
--
-- Copyright (C) 2012 Graham Ranson, Glitch Games Ltd.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this 
-- software and associated documentation files (the "Software"), to deal in the Software 
-- without restriction, including without limitation the rights to use, copy, modify, merge, 
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or 
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--
----------------------------------------------------------------------------------------------------

local GGTwitter = {}
local GGTwitter_mt = { __index = GGTwitter }

local json = require( "json" )
local oAuth = require( "oAuth" )

--- Initiates a new GGTwitter object.
-- @param consumerKey The consumer key of your app.
-- @param consumerSecret The consumer secret of your app.
-- @param listener A listener function to be called on specific events such as login/logout.
-- @param url The twitter callback url?
-- @return The new object.
function GGTwitter:new( consumerKey, consumerSecret, listener, url )
    
    local self = {}
    
    setmetatable( self, GGTwitter_mt )
    
    self.consumerKey = consumerKey
    self.consumerSecret = consumerSecret
    self.listener = listener
    self.url = url or "http://www.google.co.uk"
  
  	self.accessToken = nil
	self.accessTokenSecret = nil

	self.userID = nil
	self.screenName = nil
  
  	self:load()
  	
    return self
    
end

--- Converts a string into a table. Used internally.
-- @param str The string to convert.
-- @param delimeters A table of delimeters to split on.
-- @return The converted table.
function GGTwitter:responseToTable( str, delimeters )
	
	local obj = {}

	while str:find( delimeters[ 1 ] ) ~= nil do
	
		if #delimeters > 1 then
		
			local key_index = 1
			local val_index = str:find( delimeters[ 1 ] )
			local key = str:sub(key_index, val_index - 1 )
	
			str = str:sub( ( val_index + delimeters[ 1 ]:len() ) )
	
			local end_index
			local value
	
			if str:find( delimeters[ 2 ] ) == nil then
				end_index = str:len()
				value = str
			else
				end_index = str:find( delimeters[ 2 ] )
				value = str:sub( 1, ( end_index - 1 ) )
				str = str:sub( ( end_index + delimeters[ 2 ]:len() ), str:len() )
			end
			
			obj[ key ] = value
			
		else
	
			local val_index = str:find( delimeters[ 1 ] )
			str = str:sub( ( val_index + delimeters[ 1 ]:len() ) )
	
			local end_index
			local value
	
			if str:find( delimeters[ 1 ] ) == nil then
				end_index = str:len()
				value = str
			else
				end_index = str:find( delimeters[ 1 ] )
				value = str:sub( 1, ( end_index - 1 ) )
				str = str:sub( end_index, str:len() )
			end
			
			obj[ #obj + 1 ] = value
			
		end
		
	end
	
	return obj
	
end

--- Deauthorises the user.
function GGTwitter:deauthorise()
	
	self.accessToken = nil
	self.accessTokenSecret = nil
	self.userID = nil
	self.screenName = nil
	
	os.remove( system.pathForFile( "twitter.dat", system.DocumentsDirectory ) )
	
	if self.listener then
		self.listener{ phase = "deauthorised" }
	end
	
end

--- Authorises the user.
function GGTwitter:authorise()

	if self:isAuthorised() then
		if self.listener then
			self.listener{ phase = "authorised" }
		end
		return
	end
	
	local twitterRequest = ( oAuth.getRequestToken( self.consumerKey, self.url, "http://twitter.com/oauth/request_token", self.consumerSecret ) )
	local twitterRequestToken = twitterRequest.token
	local twitterRequestTokenSecret = twitterRequest.token_secret

	local listener = function( event )
	
		local remainOpen = true
		local url = event.url

		if url:find( "oauth_token" ) and url:find( self.url ) then
			
			native.showAlert( "a", event.phase, { "OK" } )
			
			url = url:sub( url:find( "?" ) + 1, url:len() )
	
			local authoriseResponse = self:responseToTable( url, { "=" , "&" } )
			remainOpen = false
	
			local accessResponse = self:responseToTable( oAuth.getAccessToken( authoriseResponse.oauth_token, authoriseResponse.oauth_verifier, twitterRequestToken, self.consumerKey, self.consumerSecret, "https://api.twitter.com/oauth/access_token"), { "=", "&" } )
			
			self.accessToken = accessResponse.oauth_token
			self.accessTokenSecret = accessResponse.oauth_token_secret
			self.userID = accessResponse.user_id
			self.screenName = accessResponse.screen_name
			
			if self.listener then
				self.listener{ phase = "authorised" }
			end
		
			self:save()
			
		elseif url:find( self.url ) then
		
			if self.listener then
				self.listener{ phase = "failed" }
			end
			
			remainOpen = false	
			
		end
		
		return remainOpen
		
	end
	
	if not twitterRequestToken then
		
		if self.listener then
			self.listener{ phase = "failed" }
		end
		
		return
		
	end

	local fullX = display.viewableContentWidth + -1 * ( display.screenOriginX * 2 )
	local fullY = display.viewableContentHeight + -1 * ( display.screenOriginY * 2 )
	
	native.showWebPopup( display.screenOriginX, display.screenOriginY, fullX, fullY, "http://api.twitter.com/oauth/authorize?oauth_token=" .. twitterRequestToken, { urlRequest = listener } )
			
end

--- Checks if the user is authorised.
-- @return True if the user is currently authorised, false otherwise.
function GGTwitter:isAuthorised()
	if self.accessToken then
		return true
	end
	return false
end

--- Loads the authorisation data from disk. Called internally.
function GGTwitter:load()

	local path = system.pathForFile( "twitter.dat", system.DocumentsDirectory )
	local file = io.open( path, "r" )
	
	if file then
	
		local data = json.decode( file:read( "*a" ) )
		io.close( file )
		
		if data then
			self.accessToken = data.accessToken
			self.accessTokenSecret = data.accessTokenSecret
		end
		
	end
	
end

--- Saves the authorisation data to disk. Called internally.
function GGTwitter:save()

	local data = { accessToken = self.accessToken, accessTokenSecret = self.accessTokenSecret }

	local path = system.pathForFile( "twitter.dat", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	
	if file then
		file:write( json.encode( data ) )
		io.close( file )
		file = nil
	end
	
end

--- Post a message to the users Twitter feed.
-- @param message The message to post.
-- @param image The filename of an image in system.DocumentsDirectory to post. Optional.
function GGTwitter:post( message, image )

	local params = {}
	params[ 1 ] =
	{
		key = 'status',
		value = message
	}
		
	if image then
		oAuth.makeRequestWithMedia( "http://upload.twitter.com/1/statuses/update_with_media.json", params, image, self.consumerKey, self.accessToken, self.consumerSecret, self.accessTokenSecret, "POST" )
		print("A")
	else
		oAuth.makeRequest( "http://api.twitter.com/1/statuses/update.json", params, self.consumerKey, self.accessToken, self.consumerSecret, self.accessTokenSecret, "POST" )
	end
	
	if self.listener then
		self.listener{ phase = "posted" }
	end
	
end

--- Follow a user.
-- @param name The name of the user to follow.
function GGTwitter:follow( name )

	local params = {}
	
	params[ 1 ] =
	{
		key = 'screen_name',
		value = name
	}
	params[ 2 ] =
	{
		key = 'follow',
		value = "true"
	}
	
	oAuth.makeRequest( "http://api.twitter.com/1/friendships/create.json", params, self.consumerKey, self.accessToken, self.consumerSecret, self.accessTokenSecret, "POST" )
	
	if self.listener then
		self.listener{ phase = "followed" }
	end
	
end

--- Show a native twitter popup.
-- @param message The text for the tweet.
-- @param url The link for the tweet.
-- @param image Filename of an image for the tweet. Optional.
-- @param baseDir Base directory for the image. Optional, defaults to system.DocumentsDirectory.
-- @param listener Optional callback function for the twitter event.
function GGTwitter:showPopup( message, url, image, baseDir, listener )

	local twitterListener = function( event )
		if listener then
			listener( event )
		end
	end
	
	local options = {}
	options.message = message
	options.url = url
	options.listener = twitterListener
	
	if image then
		options.image = {}
		options.image.filename = image
		options.image.baseDir = baseDir or system.DocumentsDirectory
	end

	native.showPopup( "twitter", options )
	
end

--- Destroys the Twitter object.
function GGTwitter:destroy()
	self:deauthorise()
end

return GGTwitter