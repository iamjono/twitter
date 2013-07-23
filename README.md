twitter
=======

Implements the Twitter API in Lasso via SuperTweet


Author: Jonathan Guthrie  
Last Modified: July 12, 2013  
License: Public Domain

Lasso 9 rewrite by Jonathan Guthrie, LassoSoft July 12, 2013
Based off of previous work by Jason Huck

Description
===========
Note that this is a rewrite of Jason Huck's original SuperTweet Twitter type  
Updating to native Lasso 9 syntax and methodology

A few method names were changed slightly to avoid duplicate member tag names.  
For example, there are several "show" methods, which were renamed to be more specific,  
such as ->show_user and ->show_status. A couple methods required special formatting for dates,  
so a date_toHTTP method was introduced. This and the truncate methods may later be abstracted to traits.


Sample Usage
============
// create a new instance of the twitter type  
local(t = twitter(  
        -username='xxxxxxxxx',  
        -password='xxxxxxxxx'  
)

// get the first item from the public timeline  
\#t->public_timeline->first

// get a slice of your friends timeline  
\#t->friends_timeline( -since=date->subtract( -hour=2)&)

// get 4 items from the user timeline  
\#t->user_timeline( -count=4)

// show a specific status message  
\#t->show_status(xxxxxxxxx)

// update your twitter status  
\#t->update('This Tweet Powered By Lasso.')

// get all replies  
\#t->replies

// get a list of your friends  
\#t->friends

// get a list of your followers (the -lite option does not appear to work)  
\#t->followers( -lite=true)

// view all of your direct messages  
\#t->direct_messages

// view all of your sent direct messages  
\#t->sent

// send a new direct message to a specific user  
\#t->new( -user='xxxxxxxxx', -text='Sent from Lasso. Let me know if you get this.')

		
Attributions
============
A million thanks to Jason Huck for his pre-Lasso 9 work on this.  
Also, thanks to Lieven Gekiere, Brian Loomis, and Rich Fortnum for contributions.  
Rewritten for Lasso 9 by Jonathan Guthrie, LassoSoft
