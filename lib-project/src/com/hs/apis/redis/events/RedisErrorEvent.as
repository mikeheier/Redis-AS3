//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.apis.redis.events
{
	import flash.events.Event;
	import flash.net.Socket;

	public class RedisErrorEvent extends RedisEvent
	{

		//=================================
		// constructor 
		//=================================

		public function RedisErrorEvent( error : String , socket : Socket , bubbles : Boolean = false , cancelable : Boolean = false )
		{
			super( ERROR , socket , bubbles , cancelable );
			_error = error;
		}

		//=================================
		// public static properties 
		//=================================

		public static const ERROR : String = "error";


		//=================================
		// public properties 
		//=================================

		protected var _error : String;

		public function get error() : String
		{
			return _error;
		}

		//=================================
		// public methods 
		//=================================

		override public function clone() : Event
		{
			return new RedisErrorEvent( error , socket , bubbles , cancelable );
		}

		override public function toString() : String
		{
			var s : String = super.toString();

			if( error )
				s += "\n  - " + error;
			return s;
		}
	}
}
