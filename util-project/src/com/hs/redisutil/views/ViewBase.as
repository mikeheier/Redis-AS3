//------------------------------------------------------------------------------
//	Michael Heier 
//------------------------------------------------------------------------------

package com.hs.redisutil.views
{
	import com.hs.redisutil.model.RedisModel;
	import flash.events.Event;
	import spark.components.Group;
	[Event( name = "logChanged" , type = "flash.events.Event" )]
	[Event( name = "receiverLogChanged" , type = "flash.events.Event" )]
	public class ViewBase extends Group
	{

		//=================================
		// constructor 
		//=================================

		public function ViewBase()
		{
			super();
			percentWidth = 100;
			percentHeight = 100;
			redisModel = RedisModel.getInstance();
			redisModel.addEventListener( "logChanged"
										 , function( event : Event ) : void
										 {
											 dispatchEvent( event.clone() );
										 } );

			redisModel.addEventListener( "receiverLogChanged"
										 , function( event : Event ) : void
										 {
											 dispatchEvent( event.clone() );
										 } );
		}


		//=================================
		// public properties 
		//=================================

		[Bindable]
		public var redisModel : RedisModel;
	}
}
