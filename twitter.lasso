[
/*----------------------------------------------------------------------------

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
#t->public_timeline->first

// get a slice of your friends timeline
#t->friends_timeline( -since=date->subtract( -hour=2)&)

// get 4 items from the user timeline
#t->user_timeline( -count=4)

// show a specific status message
#t->show_status(xxxxxxxxx)

// update your twitter status
#t->update('This Tweet Powered By Lasso.')

// get all replies
#t->replies

// get a list of your friends
#t->friends

// get a list of your followers (the -lite option does not appear to work)
#t->followers( -lite=true)

// view all of your direct messages
#t->direct_messages

// view all of your sent direct messages
#t->sent

// send a new direct message to a specific user
#t->new( -user='xxxxxxxxx', -text='Sent from Lasso. Let me know if you get this.')

		
Attributions
============
A million thanks to Jason Huck for his pre-Lasso 9 work on this.
Also, thanks to Lieven Gekiere, Brian Loomis, and Rich Fortnum for contributions.
Rewritten for Lasso 9 by Jonathan Guthrie, LassoSoft



----------------------------------------------------------------------------*/
		




define twitter => type {
	// Implements the Twitter API in Lasso.
	data 
		public username::string,
		public password::string,
		public version::string = '1.1'

	
	protected url(path::string) => { return 'http://api.supertweet.net/' + .version + #path }
	protected truncate(in::string,length::integer) => {
		#length <= 0 			? return string
		#in->trim
		#in->size < #length 	? return #in
		return #in->substring(1,#length)
	}
	public oncreate(-username::string='',-password::string='',-version::string='1.1') => {
		#username->size 	? .username = #username
		#password->size 	? .password = #password
		#version 			? .version = #version
	}
	
	public authcheck() => { return(.username->size && .password->size) }
	public date_toHTTP(-in::date) => {
		// HTTP-formats the given date.
		// bought into type because of potential conflict. makes everything self contained
		local(out = string)
		not #in->gmt ? #in = date_localtogmt(#in)
		#out = encode_url(#in->format('%Q %T'))->replace('%20','+')&
		return #out
	}

	public retrieve(path::string,-post::array=array) => {
	
		fail_if(not .authcheck, -1, 'Username or password not set.')
		local(response = 'There was a problem communicating with Twitter.')
		protect => {
			// using native curl construct rather than include_url for more raw speed
			handle_error => {
				log_critical(error_msg)
			}
//			return .url(#path)
			local(curl = curl(.url(#path)))
			#curl->set(CURLOPT_USERPWD, .username + ':' + .password)

			if(#post->size > 0) => {
				local(postfields = string, delimit = string)
				with param in #post
				do {
					#postfields->append(#delimit + #param->first->asString->asBytes->encodeUrl + '=' + #param->second->asString->asBytes->encodeUrl)
					local(delimit) = '&';
				}
				#curl->set(CURLOPT_POSTFIELDS, #postfields)
			}
			#curl->set(CURLOPT_TIMEOUT, 15)
			#response = #curl->result
			#response == null ? #response = 'There was a problem communicating with Twitter.'
//			#response->exportas(#string)
//			log_critical(#response)
						
//			#post->size ? #response = include_url(
//					'http://api.supertweet.net/' + .version + #path,
//					-username=.username,
//					-password=.password,
//					-postparams=#post,
//					-timeout=15
//				) | #response = include_url(
//						'http://api.supertweet.net/' + .version + #path,
//						-username=.username,
//						-password=.password,
//						-timeout=15
//					)
			
		}
		
		return json_deserialize(#response)
	}
	
	public public_timeline(-since_id::integer=0) => {
		local(path = '/statuses/public_timeline.json')
		#since_id ? #path->append('?since_id=' + #since_id)
//		return #path
		return .retrieve(#path)
	}
	public friends_timeline(-id::string=string,-since=string,-page=string) => {
		local(path = '/statuses/friends_timeline' + (#id->size ? '/' + #id) + '.json')
		local(opts = array)
		#since->isA(::date) 	? #opts->insert('since=' + .date_toHTTP(#since))
		#page->isA(::integer) 	? #opts->insert('page=' + #page)
		
		#opts->size ? #path->append('?'+#opts->join('&'))
		
		return .retrieve(#path)			
	}
	public user_timeline(-id::string=string,-since=string,-count=string) => {
		local(path = '/statuses/user_timeline' + (#id->size ? '/' + #id) + '.json')

		local(opts = array)
		#since->isA(::date) 	? #opts->insert('since=' + .date_toHTTP(#since))
		#count->isA(::integer) 	? #opts->insert('count=' + #count)
		
		#opts->size ? #path->append('?'+#opts->join('&'))

		return .retrieve(#path)			
	}
	
	public show_status(-id::integer) => {
		return .retrieve('/statuses/show/' + #id + '.json')
	}

	public update(-status::string) => {
		not #status->size ? return	
		local(path = '/statuses/update.json')
		local(post = array('status' = .truncate(#status, 160)))
		return .retrieve(#path, #post)
	}

	public replies(-page::integer=0) => {
		local(path = '/statuses/replies.json')
		#page > 0 #path->append('?page=' + #page)
		return .retrieve(#path)
	}
	public destroy_status(-id::integer) => {
		#id <= 0 ? return
		return .retrieve('/statuses/destroy/'+#id+'.json')
	}
	public friends(-id::integer=0) => {
		return .retrieve('/statuses/friends' + (#id ? '/' + #id) + '.json')
	}
	
	public followers(-id=string,-page::integer=0) => {
		local(path = '/statuses/followers' + (#id->asString->size ? '/' + #id) + '.json')
		#page > 0 #path->append('?page=' + #page)
		return .retrieve(#path)
	}

	public verify_credentials() => {
		return .retrieve('/account/verify_credentials.json')
	}
	public end_session() => {
		return .retrieve('/account/end_session')
	}
	public rate_limit_status() => {
		return .retrieve('/account/rate_limit_status.json')
	}
	public test() => {
		return .retrieve('/help/test.json')
	}

	
		
//	define_tag( // not working
//		'show_user',
//		-opt='id',
//		-opt='email', -type='string',
//		-encodenone
//	);
//		local_defined('id') ? local('path') = '/users/show/' + #id + '.json';
//		local_defined('email') ? local('path') = '/users/show.json?email=' + #email;
//		return(self->retrieve(#path));
//	/define_tag;
	

	public direct_messages(-since::date='1971-01-01',-since_id::integer=0,-page::integer=0) => {
		local(p = array)
		#since->year > 1971		? #p->insert('since=' + .date_toHTTP(#since))
		#since_id > 0			? #p->insert('since_id=' + #since_id)
		#page > 0				? #p->insert('page=' + #page)		
		return .retrieve('/direct_messages.json'+(#p->size ? '?'+#p->join('&')))
	}

	
	public sent_direct(-since::date='1971-01-01',-since_id::integer=0,-page::integer=0) => {
		local(p = array)
		#since->year > 1971		? #p->insert('since=' + .date_toHTTP(#since))
		#since_id > 0			? #p->insert('since_id=' + #since_id)
		#page > 0				? #p->insert('page=' + #page)		
		return .retrieve('/direct_messages/sent.json'+(#p->size ? '?'+#p->join('&')))
	}


	public new_direct(-user,-text::string) => {
		local(p = array(
			'user' = #user,
			'text' = string_truncate(#text, -length=140)
			)
		)
		return .retrieve('/direct_messages/new.json',#p)
	}

		
/*
	still to convert
	
	
	
	define_tag(
		'destroy_direct',
		-req='id', -type='integer',
		-encodenone
	);
		local('path') = '/direct_messages/destroy/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;

	define_tag(
		'create_friendship',
		-req='id',
		-encodenone
	);
		local('path') = '/friendships/create/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'destroy_friendship',
		-req='id',
		-encodenone
	);
		local('path') = '/friendships/destroy/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;

	define_tag(
		'exists_friendship',
		-req='user_a',
		-req='user_b',
		-encodenone
	);
		local('path') = '/friendships/exists.json?user_a=';
		#path += encode_url(#user_a) + '&user_b=' + encode_url(#user_b);
		return(self->retrieve(#path));
	/define_tag;

	define_tag(
		'ids_friends',
		-opt='id',
		-encodenone
	);
		local('path') = '/friends/ids';
		local_defined('id') ? #path += '/' + encode_url(#id);
		#path += '.json';
		return(self->retrieve(#path));
	/define_tag;

	define_tag(
		'ids_followers',
		-opt='id',
		-encodenone
	);
		local('path') = '/followers/ids';
		local_defined('id') ? #path += '/' + encode_url(#id);
		#path += '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'update_profile',
		-opt='name',
		-opt='email',
		-opt='url',
		-opt='location',
		-opt='description',
		-encodenone
	);
		fail_if(!params->size, -1, 'At least one parameter must be provided.');
		local('path') = '/account/update_profile.json';
		local('post') = array;
		
		iterate(params, local('i'));
			#post->insert(string(#i->first)->removeleading('-')& = #i->second);
		/iterate;
		
		return(self->retrieve(#path, #post));
	/define_tag;
	
	
	define_tag(
		'favorites',
		-opt='id',
		-opt='page', -type='integer',
		-encodenone
	);
		local('path') = '/favorites' + (local_defined('id') ? '/' + #id) + '.json';
		local_defined('page') ? #path += '?page=' + #page;
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'create_favorite',
		-req='id', -type='integer',
		-encodenone
	);
		local('path') = '/favorites/create/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'destroy_favorite',
		-req='id', -type='integer',
		-encodenone
	);
		local('path') = '/favorites/destroy/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'follow_notification',
		-req='id',
		-encodenone
	);
		local('path') = '/notifications/follow/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'leave_notification',
		-req='id',
		-encodenone
	);
		local('path') = '/notifications/leave/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'create_block',
		-req='id',
		-encodenone
	);
		local('path') = '/blocks/create/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	
	define_tag(
		'destroy_block',
		-req='id',
		-encodenone
	);
		local('path') = '/blocks/destroy/' + #id + '.json';
		return(self->retrieve(#path));
	/define_tag;
	define_tag(
		'update_location',
		-req='location', -type='string',
		-encodenone
	);
		local('path') = '/account/update_location.json';
		local('post') = array('location' = string_truncate(#location, 100));
		return(self->retrieve(#path, #post));
	/define_tag;

	define_tag(
		'update_delivery_device',
		-req='device', -type='string',
		-encodenone
	);
		fail_if((: 'sms', 'im', 'none') !>> #device, -1, 'Not an allowed device.');
		local('path') = '/account/update_delivery_device.json?device=' + #device;
		return(self->retrieve(#path));
	/define_tag;

	define_tag(
		'update_profile_colors',
		-opt='profile_background_color',
		-opt='profile_text_color',
		-opt='profile_link_color',
		-opt='profile_sidebar_fill_color',
		-opt='profile_sidebar_border_color',
		-encodenone
	);
		fail_if(!params->size, -1, 'At least one color must be specified.');
		local('path') = '/account/update_profile_colors.json';
		local('post') = array;
		
		iterate(params, local('i'));
			#post->insert(string(#i->first)->removeleading('-')& = #i->second);
		/iterate;
		
		return(self->retrieve(#path, #post));
	/define_tag;

*/
	

	
} // end of twitter type









define tweet => type {
	/*	=====================================================================
		Base data container for individual tweets
		Not part of "twitter" type or extenders deliberately so that it can have it's own props and methods, keeping it clean
	=====================================================================  */
	data
		public id::string,
		public username::string,
		public pubdate::date,
		public txt::string
	
}




]