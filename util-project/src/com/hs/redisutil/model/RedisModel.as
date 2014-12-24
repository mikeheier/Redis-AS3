//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.redisutil.model
{
	import com.hs.apis.redis.Redis;
	import com.hs.apis.redis.RedisCommands;
	import com.hs.apis.redis.events.RedisErrorEvent;
	import com.hs.apis.redis.events.RedisResultEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event( name = "logChanged" , type = "flash.events.Event" )]
	[Event( name = "receiverLogChanged" , type = "flash.events.Event" )]
	[Bindable]
	public class RedisModel extends EventDispatcher
	{

		//=================================
		// constructor 
		//=================================

		public function RedisModel()
		{
			super();

			if( _instance )
				throw new Error( "this is a singleton" );

			_receiver = new Redis( "127.0.0.1" );
			_receiver.addEventListener( "connected" , receiver_connectedHandler );
			_receiver.addEventListener( RedisResultEvent.RESULT , receiver_resultHandler );
			_receiver.addEventListener( RedisErrorEvent.ERROR , receiver_errorHandler );

			_redis = new Redis( "127.0.0.1" );
			_redis.addEventListener( "connected" , redis_connectedHandler );
			_redis.addEventListener( RedisResultEvent.RESULT , redis_resultHandler );
			_redis.addEventListener( RedisErrorEvent.ERROR , redis_errorHandler );

			_logCache = [];
			_receiverLogCache = [];
			log = "";
			receiverLog = "";
		}

		//=================================
		// protected static properties 
		//=================================

		protected static var _instance : RedisModel;

		//=================================
		// private static properties 
		//=================================

		private static const LOG_MAX_LEN : uint = 10000;


		//=================================
		// public properties 
		//=================================

		public var log : String;

		protected var _receiver : Redis;

		public function get receiver() : Redis
		{
			return _receiver;
		}

		public var receiverLog : String;

		protected var _redis : Redis;

		public function get redis() : Redis
		{
			return _redis;
		}

		//=================================
		// protected properties 
		//=================================

		protected var _logCache : Array;

		protected var _receiverLogCache : Array;

		//=================================
		// public static methods 
		//=================================

		public static function getInstance() : RedisModel
		{
			if( !_instance )
				_instance = new RedisModel();

			return _instance;
		}

		//=================================
		// public methods 
		//=================================

		public function appendLog( value : String ) : void
		{
			if( log.length > 0 && value && value.substr( 0 , 2 ) == ">>" )
				log += "\n";
			log += value + "\n";

			if( log.length > LOG_MAX_LEN )
			{
				var tmp : String = log.substr( 0 , LOG_MAX_LEN );
				_logCache.push( tmp );
				log = log.substr( LOG_MAX_LEN , log.length );
			}

			dispatchEvent( new Event( "logChanged" ) );
		}

		public function appendReceiverLog( value : String ) : void
		{
			if( receiverLog.length > 0 && value && value.substr( 0 , 2 ) == ">>" )
				receiverLog += "\n";
			receiverLog += value + "\n";

			if( receiverLog.length > LOG_MAX_LEN )
			{
				var tmp : String = log.substr( 0 , LOG_MAX_LEN );
				_receiverLogCache.push( tmp );
				receiverLog = receiverLog.substr( LOG_MAX_LEN , receiverLog.length );
			}

			dispatchEvent( new Event( "receiverLogChanged" ) );
		}

		public function authenticate( password : String ) : void
		{
			_receiver.authenticate( password );

			appendLog( ">> auth " + password );
			_redis.authenticate( password );
		}

		public function connect( host : String , port : uint ) : void
		{
			_receiver.init( host , port );
			_receiver.connect();

			_redis.init( host , port );
			_redis.connect();
		}

		public function execute( command : String ) : void
		{
			if( !command )
				return;

			var ary : Array = command.split( " " );

			if( ary && ary.length > 0 )
			{
				var cmd : String = ary[ 0 ];
				var params : Array = ary.slice( 1 , ary.length );
				var tmp : String = params.join( " " );
				params = tmp ? tmp.split( "," ) : null;


				if( cmd.toLocaleUpperCase() == RedisCommands.AUTH )
					authenticate( params.join( "" ) );
				else
				{
					appendLog( ">> " + command );

					if( cmd.toLocaleUpperCase() == RedisCommands.SUBSCRIBE )
						_receiver.subscribe.apply( null , params );
					else
						_redis.execute( cmd , params );
				}
			}
		}

		//=================================
		// protected methods 
		//=================================

		protected function receiver_connectedHandler( event : Event ) : void
		{

		}

		protected function receiver_errorHandler( event : RedisErrorEvent ) : void
		{
			appendReceiverLog( event.error );
		}

		protected function receiver_resultHandler( event : RedisResultEvent ) : void
		{
			for( var i : uint = 0 ; i < event.result.length ; i++ )
			{
				appendReceiverLog( event.result[ i ].result );
			}
		}

		protected function redis_connectedHandler( event : Event ) : void
		{
			// TODO Auto-generated method stub

		}

		protected function redis_errorHandler( event : RedisErrorEvent ) : void
		{
			appendLog( event.error );
		}

		protected function redis_resultHandler( event : RedisResultEvent ) : void
		{
			for( var i : uint = 0 ; i < event.result.length ; i++ )
			{
				appendLog( event.result[ i ].result );
			}
		}
	}
}
