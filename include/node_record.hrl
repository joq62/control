-record(node_record,{
		     allocated_id,
		     hostname,
		     nodename,
		     node_dir,
		     cookie_str,
		     status,        % free,allocated, not_created, deleted
		     status_time,   % when latest status was changed
		     node
		    }).
