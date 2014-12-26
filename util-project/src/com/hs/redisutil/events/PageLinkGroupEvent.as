//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.redisutil.events
{
	import flash.events.Event;

	public class PageLinkGroupEvent extends Event
	{

		//=================================
		// constructor 
		//=================================

		public function PageLinkGroupEvent( type : String , page : uint = 0 , bubbles : Boolean = false , cancelable : Boolean = false )
		{
			super( type , bubbles , cancelable );
			_page = page;
		}

		//=================================
		// public static properties 
		//=================================

		public static var ACTIVE_PAGE_SELECTED : String = "activePageSelected";

		public static var PAGE_SELECTED : String = "pageSelected";


		//=================================
		// public properties 
		//=================================

		protected var _page : uint;

		public function get page() : uint
		{
			return _page;
		}

		//=================================
		// public methods 
		//=================================

		override public function clone() : Event
		{
			return new PageLinkGroupEvent( type , page , bubbles , cancelable );
		}
	}
}
