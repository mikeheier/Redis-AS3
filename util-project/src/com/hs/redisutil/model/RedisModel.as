//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.redisutil.model
{
	import com.hs.apis.redis.Redis;
	import com.hs.apis.redis.RedisCommands;
	import com.hs.apis.redis.events.RedisErrorEvent;
	import com.hs.apis.redis.events.RedisResultEvent;
	import com.hs.redisutil.components.PageLinkGroup;
	import com.hs.redisutil.events.PageLinkGroupEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import mx.utils.StringUtil;

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

		private static const LOG_MAX_LEN : uint = 500;


		//=================================
		// public properties 
		//=================================

		public var log : String;

		public var outputPageDetails : String;

		public var recPageDetails : String;

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

		protected var _logPageLinkGroup : PageLinkGroup;

		protected var _recPageLinkGroup : PageLinkGroup;

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
			_appendLog( "log" , value );
		}

		public function appendReceiverLog( value : String ) : void
		{
			_appendLog( "receiverLog" , value );
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

			command = StringUtil.trim( command );
			var ary : Array = command.split( " " );
			ary.forEach( function( item : String , index : int , array : Array ) : void
			{
				ary[ index ] = StringUtil.trim( item );
			} );

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

		public function initPageLinkGroups( logPageLinkGroup : PageLinkGroup , recPageLinkGroup : PageLinkGroup ) : void
		{
			_recPageLinkGroup = recPageLinkGroup;
			_logPageLinkGroup = logPageLinkGroup;
		}

		public function outputPage_activePageSelectedHandler( event : PageLinkGroupEvent ) : void
		{
			outputPageDetails = null;
		}

		public function outputPage_selectedHandler( event : PageLinkGroupEvent ) : void
		{
			outputPageDetails = _logCache[ event.page - 1 ];
		}

		public function recPage_activePageSelectedHandler( event : PageLinkGroupEvent ) : void
		{
			recPageDetails = null;
		}

		public function recPage_selectedHandler( event : PageLinkGroupEvent ) : void
		{
			recPageDetails = _receiverLogCache[ event.page - 1 ];
		}

		//=================================
		// protected methods 
		//=================================



		protected function _appendLog( logName : String , value : String ) : void
		{
			var _l : String = this[ logName ];

			if( _l.length > 0 && value && value.substr( 0 , 2 ) == ">>" )
				_l += "\n";
			_l += value + "\n";

			var lines : Array = _l.split( "\n" );

			if( lines.length > LOG_MAX_LEN )
			{
				var tmp : Array = lines.slice( 0 , LOG_MAX_LEN );
				var lc : Array = getLogCache( logName );
				lc.push( tmp.join( "\n" ) );
				getPageLinkGroup( logName ).addPage( lc.length );
				_l = lines.slice( LOG_MAX_LEN , lines.length ).join( "\n" );
			}

			this[ logName ] = _l

			dispatchEvent( new Event( logName + "Changed" ) );
		}

		protected function getLogCache( logName : String ) : Array
		{
			switch( logName )
			{
				case "receiverLog":
					return _receiverLogCache;
				default:
					return _logCache;
			}
		}

		protected function getPageLinkGroup( logName : String ) : PageLinkGroup
		{
			switch( logName )
			{
				case "receiverLog":
					return _recPageLinkGroup;
				default:
					return _logPageLinkGroup;
			}
		}

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
			appendLog( ">> connected: " + _redis.host + ":" + _redis.port );
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
