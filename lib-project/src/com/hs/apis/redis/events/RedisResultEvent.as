//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.apis.redis.events
{
	import flash.events.Event;
	import flash.net.Socket;

	public class RedisResultEvent extends RedisEvent
	{

		//=================================
		// constructor 
		//=================================

		public function RedisResultEvent( result : Array , socket : Socket , bubbles : Boolean = false , cancelable : Boolean = false )
		{
			super( RESULT , socket , bubbles , cancelable );
			_result = result;
		}

		//=================================
		// public static properties 
		//=================================

		public static const RESULT : String = "result";


		//=================================
		// public properties 
		//=================================

		protected var _result : Array;

		public function get result() : Array
		{
			return _result;
		}

		//=================================
		// public methods 
		//=================================

		override public function clone() : Event
		{
			return new RedisResultEvent( result , socket , bubbles , cancelable );
		}

		override public function toString() : String
		{
			var s : String = super.toString();

			if( result )
				s += "\n  - " + _result.join( "\n  - " );
			return s;
		}
	}
}
