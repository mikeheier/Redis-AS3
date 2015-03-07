Redis-AS3
=========

An AS3 library for redis

Table of Contents
-----------------

* [References](#references)
* [Usage](#usage)
* [Redis Utility](#redis-utility)

References
----------
	- https://github.com/danielwanja/redis_flex
	- http://redis.io

Usage
-----

The api is extremely simple and all commands can be executed using the <strong><i>execute</i></strong> function.  There are a few commands that are specifically implemented such as authentication and pub/sub functionality.


```
//the default port is 6379
redis = new Redis("127.0.0.1", 6379);
redis.addEventListener( "connected" , redis_connectedHandler );
redis.addEventListener( RedisResultEvent.RESULT , redis_resultHandler );
redis.addEventListener( RedisErrorEvent.ERROR , redis_errorHandler );

function redis_resultHandler( event:RedisResultEvent ):void
{
	for( var i : uint = 0 ; i < event.result.length ; i++ )
	{
		trace( event.result[ i ].result );
	}
}

function redis_errorHandler( event:RedisErrorEvent ):void
{
	trace( event.error );
}

function redis_connectedHandler( event : Event ) : void
{
	//once connected, you can execute any command

	//authenticate
	redis.execute( "AUTH" , [ "apassword" ] );
	//or
	redis.authenticate( "apassword" )

	//info
	redis.execute( "INFO" );

	//ping
	redis.execute( "PING" );

	//subscribe
	redis.execute( "SUBSCRIBE", ["ch1","ch2","ch3"] );
	//or
	redis.subscribe("ch1","ch2","ch3");

	//unsubscribe
	redis.execute( "UNSUBSCRIBE", ["ch1","ch2","ch3"] );
	//or
	redis.unsubscribe("ch1","ch2","ch3");

	//publish
	redis.execute( "PUBLISH" , [ "ch1" , "hello ch1" ] );
	//or
	redis.publish( "ch1" , "hello ch1" );
}
```

Redis Utility
-------------
The <strong><i>Redis Utility</i></strong> inlcuded in this project is a simple application using the <strong><i>Redis-AS3</i></strong> library.  You can use this application to test out the api and/or redis.