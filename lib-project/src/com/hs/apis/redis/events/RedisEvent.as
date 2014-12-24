//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.apis.redis.events
{
	import flash.events.Event;
	import flash.net.Socket;

	public class RedisEvent extends Event
	{

		//=================================
		// constructor 
		//=================================

		public function RedisEvent( type : String , socket : Socket , bubbles : Boolean = false , cancelable : Boolean = false )
		{
			super( type , bubbles , cancelable );
			_socket = socket;
		}


		//=================================
		// public properties 
		//=================================

		protected var _socket : Socket;

		public function get socket() : Socket
		{
			return _socket;
		}

		//=================================
		// public methods 
		//=================================

		override public function clone() : Event
		{
			return new RedisEvent( type , socket , bubbles , cancelable );
		}
	}
}
