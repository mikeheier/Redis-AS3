//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.apis.redis
{

	public class RedisResult extends Object
	{

		//=================================
		// constructor 
		//=================================

		public function RedisResult( type : String , result : * )
		{
			super();
			_type = type;
			_result = result;
		}


		//=================================
		// public properties 
		//=================================

		private var _result : *;

		public function get result() : *
		{
			return _result;
		}

		public function set result( value : * ) : void
		{
			_result = value;
		}

		private var _type : String;

		public function get type() : String
		{
			return _type;
		}

		//=================================
		// public methods 
		//=================================

		public function toString() : String
		{
			return _type + " | " + _result;
		}
	}
}
