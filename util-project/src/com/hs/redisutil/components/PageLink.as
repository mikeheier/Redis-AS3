//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.redisutil.components
{
	import spark.components.Label;

	public class PageLink extends Label
	{

		//=================================
		// constructor 
		//=================================

		public function PageLink( page : uint = 0 )
		{
			super();
			this.page = page;
			useHandCursor = true;
			buttonMode = true;
		}


		//=================================
		// public properties 
		//=================================

		protected var _page : uint;

		public function get page() : uint
		{
			return _page;
		}

		public function set page( value : uint ) : void
		{
			_page = value;
			text = page.toString();
		}
	}
}
