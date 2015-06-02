//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.apis.redis
{
	import com.hs.apis.redis.events.RedisErrorEvent;
	import com.hs.apis.redis.events.RedisResultEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;

	[Event( name = "error" , type = "com.hs.apis.redis.events.RedisErrorEvent" )]
	[Event( name = "result" , type = "com.hs.apis.redis.events.RedisResultEvent" )]
	[Event( name = "closed" , type = "flash.events.Event" )]
	[Event( name = "connected" , type = "flash.events.Event" )]
	[Event( name = "disconnected" , type = "flash.events.Event" )]
	public class Redis extends EventDispatcher
	{

		//=================================
		// constructor 
		//=================================

		public function Redis( host : String = null , port : int = 6379 )
		{
			super();
			init( host , port );
			connect();
		}

		//=================================
		// protected static properties 
		//=================================

		protected static const EOL : String = "\r\n";


		//=================================
		// public properties 
		//=================================

		[Bindable( "closed" )]
		[Bindable( "connected" )]
		[Bindable( "disconnected" )]
		public function get connected() : Boolean
		{
			return _socket && _socket.connected;
		}

		protected var _host : String;

		public function get host() : String
		{
			return _host;
		}

		public function set host( value : String ) : void
		{
			_host = value;
		}

		protected var _port : int = 6379;

		public function get port() : int
		{
			return _port;
		}

		public function set port( value : int ) : void
		{
			_port = value;
		}

		//=================================
		// protected properties 
		//=================================

		protected var _executingCommand : Boolean;

		protected var _password : String;

		protected var _previousPacketFragment : String = "";

		protected var _queue : Vector.<String>;

		protected var _socket : Socket;

		protected var _subscribedChannels : Vector.<String>;

		//=================================
		// public methods 
		//=================================

		public function authenticate( pwd : String ) : void
		{
			execute( RedisCommands.AUTH , [ pwd ] );
		}

		public function close() : void
		{
			if( _socket )
			{
				if( _socket.connected )
				{
					unsubscribeAll();
					_socket.close();
					dispatchEvent( new Event( "closed" ) );
				}

				_socket.removeEventListener( Event.CLOSE , socket_eventHandler );
				_socket.removeEventListener( Event.CONNECT , socket_eventHandler );
				_socket.removeEventListener( IOErrorEvent.IO_ERROR , socket_eventHandler );
				_socket.removeEventListener( OutputProgressEvent.OUTPUT_PROGRESS , socket_outPutProgressHandler );
				_socket.removeEventListener( ProgressEvent.SOCKET_DATA , socket_dataHandler );
				_socket.removeEventListener( SecurityErrorEvent.SECURITY_ERROR , socket_eventHandler );
			}
		}

		public function connect() : void
		{
			_queue = Vector.<String>( [] );
			_subscribedChannels = null;
			close();

			if( _host )
			{
				_socket = new Socket();
				_socket.addEventListener( Event.CONNECT , socket_eventHandler );
				_socket.addEventListener( IOErrorEvent.IO_ERROR , socket_eventHandler );
				_socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR , socket_eventHandler );

				_socket.connect( _host , _port );
			}
		}

		/**
		 * See http://redis.io/topics/protocol
		 *         *<number of arguments> CR LF
		 *         $<number of bytes of argument 1> CR LF
		 *         <argument data> CR LF
		 *         ...
		 *         $<number of bytes of argument N> CR LF
		 *         <argument data> CR LF
		 *
		 * @arg params - can be either the command as a String, i.e. "GET ABC" or
		 *               can be the parts in an array i.e. ["GET", "THIS IS A LONG VALUE"]
		 *
		 * Note current implement of passing an array is to avoid having to deal with the string
		 * parsing.
		 */
		public function encode( params : * ) : String
		{
			var parts : Array = params is Array ? params : params.split( " " );
			var result : Array = [];
			result.push( "*" + parts.length );

			for each( var part : String in parts )
			{
				result.push( "$" + part.length );
				result.push( part );
			}
			var r : String = result.join( EOL ) + EOL;
			log( r );
			return r;
		}

		public function execute( command : String , params : Array = null ) : void
		{
			if( !command )
			{
				dispatchError( "null command" );
				return;
			}

			if( !_socket || !_socket.connected )
			{
				dispatchError( "socket not connected" );
				return;
			}

			var args : Array = [ command ];

			if( params && params.length )
				args = args.concat( params );
			var cmd : String = encode( args );
			_queue.push( cmd );
			runQueue();
		}

		public function init( host : String , port : int = 6379 ) : void
		{
			_host = host;
			_port = port;
			log( _host , ":" , _port );
		}

		/**
		 * Publishes a message to the given channel
		 *
		 * @param channel the channel to post to
		 * @param message the payload
		 *
		 */
		public function publish( channel : String , message : String ) : void
		{
			if( !channel || !message )
				return;

			execute( RedisCommands.PUBLISH , [ channel , message ] );
		}

		/**
		 * Publishes a message to all the subcribed channels
		 *
		 * @param message
		 * @return all the channels that received the message
		 *
		 */
		public function publishAll( message : String ) : Vector.<String>
		{
			if( !message )
				return null;

			if( _subscribedChannels && _subscribedChannels.length > 0 )
			{
				for( var i : uint = 0 ; i < _subscribedChannels.length ; i++ )
				{
					publish( _subscribedChannels[ i ] , message );
				}

			}

			return _subscribedChannels;
		}

		/**
		 * Adds a subscription to the specified channels.
		 *
		 * @param channels - channels to subscribe to
		 * @return returns the all the channels subscribed to
		 *
		 */
		public function subscribe( ... channels ) : Vector.<String>
		{
			if( channels && channels.length )
			{
				if( !_subscribedChannels )
					_subscribedChannels = Vector.<String>( [] );

				var added : Array = [];

				for( var i : uint = 0 ; i < channels.length ; i++ )
				{
					var j : int = _subscribedChannels.indexOf( channels[ i ] );

					if( j == -1 )
					{
						added.push( channels[ i ] );
						_subscribedChannels.push( channels[ i ] );
						continue;
					}
				}

				if( added.length )
				{
					execute( RedisCommands.SUBSCRIBE , added );
				}
			}

			return _subscribedChannels;
		}

		/**
		 * Removes a subscription for the specified channels.
		 *
		 * @param channels - channels to unsubscribe to
		 * @return returns the all the channels subscribed to
		 *
		 */
		public function unsubscribe( ... channels ) : Vector.<String>
		{
			if( channels && channels.length && _subscribedChannels && _subscribedChannels.length > 0 )
			{
				var removed : Array = [];

				for( var i : uint = 0 ; i < channels.length ; i++ )
				{
					var j : int = _subscribedChannels.indexOf( channels[ i ] );

					if( j > -1 )
					{
						_subscribedChannels.splice( j , 1 );
						removed.push( channels[ i ] );
						continue;
					}
				}

				if( removed.length )
				{
					execute( RedisCommands.UNSUBSCRIBE , removed );
				}
			}

			return _subscribedChannels;
		}

		/**
		 * Removes all channel subscriptions.
		 *
		 * @return returns all the channels that were subscribed to
		 *
		 */
		public function unsubscribeAll() : Vector.<String>
		{
			var tmp : Array;

			if( _socket && _socket.connected && _subscribedChannels && _subscribedChannels.length > 0 )
			{
				tmp = [];

				for( var i : uint = 0 ; i < _subscribedChannels.length ; i++ )
				{
					tmp.push( _subscribedChannels[ i ] );
				}

				execute( RedisCommands.UNSUBSCRIBE , tmp );
				_subscribedChannels = null;
			}

			return tmp ? Vector.<String>( tmp ) : null;
		}

		//=================================
		// protected methods 
		//=================================

		protected function dispatchError( error : String ) : void
		{
			dispatchEvent( new RedisErrorEvent( error , _socket ) );
		}

		protected function log( ... args ) : void
		{
			//trace.apply( null, args );
		}

		protected function parseResults( rawData : String ) : ParseResult
		{
			if( !rawData )
				return new ParseResult();

			if( _previousPacketFragment )
				log( "_previousPacketFragment" , _previousPacketFragment.replace( /\r\n/g , "|" ) );

			var results : Array = [];
			var errors : Array = [];
			var terminated : Boolean;
			var str : String = _previousPacketFragment + rawData;
			_previousPacketFragment = "";
			var lines : Vector.<String> = Vector.<String>( str.split( EOL ) );
			var line : String;
			var char : String;
			var isBulk : Boolean;
			var bulkLen : int;
			var bulk : String;
			var aryLen : int;
			var ary : Array;
			var aryStr : String;

			terminated = str.substr( str.length - 2 , 2 ) === EOL;

			function addResult( data : * , rtype : String , resultsArray : Array , tmpAry : Array ) : void
			{
				if( tmpAry )
					tmpAry.push( data );
				else
					resultsArray.push( new RedisResult( rtype , data ) );
			}

			il: for( var i : uint = 0 ; i < lines.length ; i++ )
			{
				line = lines[ i ];
				char = line.charAt();

				if( aryStr )
					aryStr += EOL + line;

				if( i == lines.length - 1
					&& ( !terminated
					|| ( ary && ary.length != aryLen )
					|| ( isBulk && bulkLen > 0 && bulk.length != bulkLen ) ) )
				{
					//are we building an array?
					if( ary )
						_previousPacketFragment = aryStr;
					else if( isBulk )
						_previousPacketFragment = "$" + bulkLen + EOL + bulk;
					else //else is simple
						_previousPacketFragment = line;
				}
				else if( isBulk )
				{
					if( bulk )
						bulk += EOL;
					bulk += line;

					if( bulk.length == bulkLen
						|| bulkLen == -1 )
					{
						addResult( bulk , RedisResultType.STRING_BULK , results , ary );
						bulkLen = 0;
						isBulk = false;
						bulk = null;
					}
				}
				else
				{
					sw1: switch( char )
					{
						case "-": //error byte
							//-ERROR message\r\n
							addResult( line.substr( line.indexOf( " " ) + 1 , line.length ) , RedisResultType.ERROR , errors , null );
							break sw1;
						case "+": //simple string byte
							addResult( line.substr( 1 , line.length ) , RedisResultType.STRING_SIMPLE , results , ary );
							break sw1;
						case ":": //int byte
							addResult( int( line.substr( 1 , line.length ) ) , RedisResultType.INTEGER , results , ary );
							break sw1;
						case "$":
							bulk = "";
							bulkLen = uint( line.substr( 1 , line.length ) );
							isBulk = true;
							continue;
						case "*": //array byte
							aryStr = line;
							ary = new Array();
							aryLen = uint( line.substr( 1 , line.length ) );
							break sw1;
						default:
							if( i < lines.length - 1 )
							{
								log( "default: " , char );
								break il;
							}
					}
				}

				if( aryLen > 0 && ary.length == aryLen )
				{
					addResult( ary , RedisResultType.ARRAY , results , null );
					aryStr = "";
					ary = null;
					aryLen = 0;
				}
			}

			return new ParseResult( results , errors );
		}

		protected function runQueue() : void
		{
			if( _queue.length > 0 && !_executingCommand )
			{
				var command : String = _queue.shift();

				try
				{
					_executingCommand = true;
					_socket.writeUTFBytes( command );
					_socket.flush();
				}
				catch( e : Error )
				{
					_executingCommand = false;
					log( e );
				}
			}
		}

		protected function socket_dataHandler( event : ProgressEvent ) : void
		{
			var pr : ParseResult = parseResults( _socket.readUTFBytes( _socket.bytesAvailable ) );
			var i : uint;

			if( pr.errors.length > 0 )
			{
				for each( var err : RedisResult in pr.errors )
					dispatchError( err.result );
			}
			else
				dispatchEvent( new RedisResultEvent( pr.results , _socket ) );
		}

		protected function socket_eventHandler( event : Event ) : void
		{
			log( event );

			switch( event.type )
			{
				case Event.CONNECT:

					_socket.addEventListener( OutputProgressEvent.OUTPUT_PROGRESS , socket_outPutProgressHandler );
					_socket.addEventListener( ProgressEvent.SOCKET_DATA , socket_dataHandler );

					//the close event is dispatched when the server closes the connection
					//see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/Socket.html#close%28%29
					_socket.addEventListener( Event.CLOSE , socket_eventHandler );

					dispatchEvent( new Event( "connected" ) );
					break;

				case Event.CLOSE:
					close();
					dispatchEvent( new Event( "disconnected" ) );
					break;

				case IOErrorEvent.IO_ERROR:
					dispatchError( IOErrorEvent( event ).text );
					break;
			}
		}

		protected function socket_outPutProgressHandler( event : OutputProgressEvent ) : void
		{
			_executingCommand = event.bytesPending > 0;
			runQueue();
		}
	}
}

class ParseResult
{

	//=================================
	// constructor 
	//=================================

	public function ParseResult( results : Array = null , errors : Array = null )
	{
		this.results = results || [];
		this.errors = errors || [];
	}


	//=================================
	// public properties 
	//=================================

	public var errors : Array;
	public var results : Array;
}
