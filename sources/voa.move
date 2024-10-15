module my_addrx::Community {
    use std::signer;
    use aptos_framework::event;
    use std::vector;

    friend my_addrx::tests;

    // Errors
    const E_NOT_INITIALIZED: u64 = 1;
    const ECOMMUNITY_DOESNT_EXIST: u64 = 2;
    const E_NOT_AUTHORIZED: u64 = 3;
    const E_NOT_FOUND: u64 = 4;
    const E_ALREADY_MEMBER: u64 = 5;
    const E_NOT_MEMBER: u64 = 6;

    // Community, Proposals, Polls, Posts, Comments
    struct CommunitiesList has key {
        communities: vector<Community>,
    }

    struct Community has store, drop, copy {
        community_id: vector<u8>,
        address: address,
        config: Config,
        posts: vector<Post>,
        proposals: vector<Proposal>,
        polls: vector<Poll>,
        members: vector<address>,
    }

    struct Post has store, drop, copy {
        id: vector<u8>,
        creator: address,
        content: vector<u8>,
        comments: vector<Comment>,
        applauds: vector<address>, // Store addresses of applauding users
    }

    struct Proposal has store, drop, copy {
        id: vector<u8>,
        creator: address,
        title: vector<u8>,
        description: vector<u8>,
        votes: vector<Vote>,
        comments: vector<Comment>,
    }

    struct Poll has store, drop, copy {
        id: vector<u8>,
        creator: address,
        question: vector<u8>,
        options: vector<vector<u8>>,
        votes: vector<address>, // Store addresses of voters
    }

    struct Comment has store, drop, copy {
        id: vector<u8>,
        creator: address,
        content: vector<u8>,
        applauds: vector<address>, // Store addresses of applauding users
    }

    struct Vote has store, drop, copy {
        power: u64,
        age: u64,
    }

    struct ConfigProp has store, drop, copy {
        minimum_voice_power: u64,
        minimum_voice_age: u64
    }

    struct Config has store, drop, copy {
        post: ConfigProp,
        comment: ConfigProp,
        proposal: ConfigProp,
        poll: ConfigProp
    }

    #[event]
    struct CreateCommunityEvent has store, drop, copy {
    community_id: vector<u8>,
    creator: address,
    config: Config,
}

#[event]
       struct CreatePostEvent has store, drop, copy {
        post_id: vector<u8>,
        creator: address,
        content: vector<u8>,
    }

     #[event]
    struct CreateProposalEvent has store, drop, copy {
        proposal_id: vector<u8>,
        creator: address,
        title: vector<u8>,
        description: vector<u8>,
    }

    #[event]
    struct CreatePollEvent has store, drop, copy {
        poll_id: vector<u8>,
        creator: address,
        question: vector<u8>,
        options: vector<vector<u8>>,
    }

    #[event]
    struct CreateCommentEvent has store, drop, copy {
        comment_id: vector<u8>,
        creator: address,
        content: vector<u8>,
    }

    #[event]
    struct VoteEvent has store, drop, copy {
        post_or_proposal_id: u64,
        voter: address,
        vote_power: u64,
    }

    #[event]
    struct ApplaudEvent has store, drop, copy {
        applauded_id: vector<u8>,
        applauder: address,
    }

    #[event]
    struct JoinCommunityEvent has store, drop, copy {
        community_id: vector<u8>,
        user_address: address,
    }

    #[event]
    struct LeaveCommunityEvent has store, drop, copy {
        community_id: vector<u8>,
        user_address: address,
    }

    // Module initialization
    fun init_module(account: &signer) {
         let signer_address = signer::address_of(account);
         assert!(signer_address == @my_addrx, E_NOT_AUTHORIZED);

        let communities_list = CommunitiesList {
            communities: vector::empty(),
        };
        move_to(account, communities_list);
    }

    // Creating a new community
    public entry fun create_community(account: &signer, 
    community_id: vector<u8>,
                                   min_voice_power_post: u64, 
                                   min_voice_age_post: u64, 
                                   min_voice_power_comment: u64, 
                                   min_voice_age_comment: u64, 
                                   min_voice_power_proposal: u64, 
                                   min_voice_age_proposal: u64, 
                                   min_voice_power_poll: u64, 
                                   min_voice_age_poll: u64) acquires CommunitiesList {
    let signer_address = signer::address_of(account);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);

    let new_config = Config {
        post: ConfigProp { minimum_voice_power: min_voice_power_post, minimum_voice_age: min_voice_age_post },
        comment: ConfigProp { minimum_voice_power: min_voice_power_comment, minimum_voice_age: min_voice_age_comment },
        proposal: ConfigProp { minimum_voice_power: min_voice_power_proposal, minimum_voice_age: min_voice_age_proposal },
        poll: ConfigProp { minimum_voice_power: min_voice_power_poll, minimum_voice_age: min_voice_age_poll }
    };

    let new_community = Community {
        community_id,
        address: signer_address,
        config: new_config,
        posts: vector::empty(),
        proposals: vector::empty(),
        polls: vector::empty(),
        members: vector::empty(),
    };

    vector::push_back(&mut communities_list.communities, new_community);

    // Create a new event instance to emit
    let community_event = CreateCommunityEvent {
        community_id,
        creator: signer_address,
        config: new_config,
    };

    event::emit(community_event);
}

  // Function to get the list of communities
    public fun get_communities(account: &signer): vector<Community> acquires CommunitiesList {
        let communities_list = borrow_global<CommunitiesList>(signer::address_of(account));
        communities_list.communities
    }

       public fun get_communities_v2(): vector<Community> acquires CommunitiesList {
        let communities_list = borrow_global<CommunitiesList>(@my_addrx);
        communities_list.communities
    }

    public fun get_members(community: &Community): &vector<address> {
        &community.members
    }

    //join community
    public entry fun join_community(account: &signer, community_id: vector<u8>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    
    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

       // Check if the user is already a member
    let len = vector::length(&community.members);
    for (i in 0..len) {
        if (*vector::borrow(&community.members, i) == signer_address) {
            abort E_ALREADY_MEMBER // Define a custom error for this scenario
        };
    };

     vector::push_back(&mut community.members, signer_address);

    // Emit an event for joining the community
    let join_event = JoinCommunityEvent {
       community_id,
        user_address: signer_address,
    };
    event::emit(join_event);
}

    //leave community
    public entry fun leave_community(account: &signer, community_id: vector<u8>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    
    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    // Check if the user is a member
let len = vector::length(&community.members);
    let found: bool = false;
    let index: u64 = 0;

    for (i in 0..len) {
        if (*vector::borrow(&community.members, i) == signer_address) {
            found = true;
            index = i;
            break
        };
    };
    assert!(found, E_NOT_MEMBER); 
    
     vector::remove(&mut community.members, index);

    // Emit an event for leaving the community
    let leave_event = LeaveCommunityEvent{
       community_id,
        user_address: signer_address,
    };
    event::emit(leave_event);
}

// Create a post in a community
public entry fun create_post(account: &signer, community_id: vector<u8>, post_id: vector<u8>, content: vector<u8>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    
    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);


    let new_post = Post {
        id: post_id,
        creator: signer_address,
        content, // Assuming you're passing content as a parameter
        comments: vector::empty<Comment>(),
        applauds: vector::empty<address>(),
    };

    vector::push_back(&mut community.posts, new_post);

    let my_event = CreatePostEvent {
        post_id,
        creator: signer_address,
        content, // Assuming you're passing content as a parameter
    };
    event::emit(my_event);
}

public fun get_posts(community: &Community): &vector<Post> {
        &community.posts
    }

    // Add functions for creating proposals, polls, comments, and applauds...

    public entry fun create_proposal(account: &signer, community_id: vector<u8>, proposal_id: vector<u8>, title: vector<u8>, description: vector<u8>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);
    
    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    
    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    let proposal = Proposal {
        id: proposal_id,
        title: title,
        description,
        creator: signer_address,
        votes: vector::empty(),
        comments: vector::empty<Comment>(),
    };

    vector::push_back(&mut community.proposals, proposal);

    let proposal_event = CreateProposalEvent {
        proposal_id,
        title,
        creator: signer_address,
         description,
    };

    event::emit(proposal_event);
}

public fun get_proposals(community: &Community): &vector<Proposal> {
        &community.proposals
    }

public entry fun create_poll(account: &signer, community_id: vector<u8>, poll_id: vector<u8>, question: vector<u8>, options: vector<vector<u8>>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);
    
    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);

    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    let poll = Poll {
        id: poll_id,
        question,
        options,
        creator: signer_address,
        votes: vector::empty(), // Initialize with an empty vector for votes
    };

     vector::push_back(&mut community.polls, poll);

    let poll_event = CreatePollEvent {
        poll_id,
        question,
        creator: signer_address,
        options,
    };

    event::emit(poll_event);
}

public entry fun create_comment(account: &signer, community_id: vector<u8>, post_id: vector<u8>, comment_id: vector<u8>, content: vector<u8>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    
    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    let post_index = find_post_index(&community.posts, post_id);
    let post = vector::borrow_mut<Post>(&mut community.posts, post_index);

    let comment = Comment {
        id: comment_id,
        content,
        creator: signer_address,
        applauds: vector::empty()
    };

    vector::push_back(&mut post.comments, comment);

    let comment_event = CreateCommentEvent {
        comment_id,
        content,
        creator: signer_address,
    };

    event::emit(comment_event);
}

public entry fun create_applaud(account: &signer, community_id: vector<u8>, post_id: vector<u8>, applauded_id: vector<u8>) acquires CommunitiesList {
    let signer_address = signer::address_of(account);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    
    // Use a helper function to find the index of the community
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    let post_index = find_post_index(&community.posts, post_id);
    let post = vector::borrow_mut<Post>(&mut community.posts, post_index);

    
    vector::push_back(&mut post.applauds, signer_address);

    let applaud_event = ApplaudEvent {
        applauded_id,
        applauder: signer_address,
    };

    event::emit(applaud_event);
}

    //view functions
    #[view]
    public fun get_user_communities(account: address): vector<Community> acquires CommunitiesList {
        // assert!(exists<CommunitiesList>(account), E_NOT_INITIALIZED);
        let global_communities = borrow_global<CommunitiesList>(@my_addrx);
        let total_communities = vector::length(&global_communities.communities);

        // List to collect the communities that the user is a part of
    let user_communities = vector::empty<Community>();
      // Iterate over all communities to check if the user is either a creator or a member
    for (i in 0..total_communities) {
        let community = vector::borrow(&global_communities.communities, i);

        // Check if the user is either the creator of the community or a member
        if (community.address == account || is_user_a_member(&community.members, account)) {
            vector::push_back(&mut user_communities, *community);
        };
    };

    user_communities
    }

#[view]
public fun get_user_posts(account: address, community_id: vector<u8>): vector<Post> acquires CommunitiesList {
    let communities_list = borrow_global<CommunitiesList>(@my_addrx);

    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow(&communities_list.communities, community_index);

    // Collect posts created by the user
    let user_posts = vector::empty<Post>();
    let total_posts = vector::length(&community.posts);

    for (i in 0..total_posts) {
        let post = vector::borrow(&community.posts, i);
        if (post.creator == account) {
            vector::push_back(&mut user_posts, *post);
        };
    };

    user_posts
}


#[view]
public fun get_user_proposals(account: address, community_id: vector<u8>): vector<Proposal> acquires CommunitiesList {
    let communities_list = borrow_global<CommunitiesList>(@my_addrx);  // Global CommunitiesList

    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow(&communities_list.communities, community_index);

    // Collect proposals created by the user
    let user_proposals = vector::empty<Proposal>();
    let total_proposals = vector::length(&community.proposals);

    for (i in 0..total_proposals) {
        let proposal = vector::borrow(&community.proposals, i);
        if (proposal.creator == account) {
            vector::push_back(&mut user_proposals, *proposal);
        };
    };

    user_proposals
}


#[view]
public fun get_user_polls(account: address, community_id: vector<u8>): vector<Poll> acquires CommunitiesList {
    let communities_list = borrow_global<CommunitiesList>(@my_addrx);  // Global CommunitiesList

    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow(&communities_list.communities, community_index);

    // Collect polls created by the user
    let user_polls = vector::empty<Poll>();
    let total_polls = vector::length(&community.polls);

    for (i in 0..total_polls) {
        let poll = vector::borrow(&community.polls, i);
        if (poll.creator == account) {
            vector::push_back(&mut user_polls, *poll);
        };
    };

    user_polls
}



    #[view]
    public fun get_all_communities(): vector<Community> acquires CommunitiesList {
        // assert!(exists<CommunitiesList>(account), E_NOT_INITIALIZED);
        let communities_list = borrow_global<CommunitiesList>(@my_addrx);
        communities_list.communities
    }

       #[view]
    public fun get_all_posts(community_id: vector<u8>): vector<Post> acquires CommunitiesList {
    // assert!(exists<CommunitiesList>(account), E_NOT_INITIALIZED);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
 let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    community.posts
}

    #[view]
    public fun get_all_proposals(community_id: vector<u8>): vector<Proposal> acquires CommunitiesList {
    // assert!(exists<CommunitiesList>(account), E_NOT_INITIALIZED);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    community.proposals
}

   #[view]
    public fun get_all_polls(community_id: vector<u8>): vector<Poll> acquires CommunitiesList {
    // assert!(exists<CommunitiesList>(account), E_NOT_INITIALIZED);

    let communities_list = borrow_global_mut<CommunitiesList>(@my_addrx);
    let community_index = find_community_index(&communities_list.communities, community_id);
    let community = vector::borrow_mut<Community>(&mut communities_list.communities, community_index);

    community.polls
}

    // Function to find the community index by ID
    public(friend) fun find_community_index(communities: &vector<Community>, community_id: vector<u8>): u64 {
        let len = vector::length(communities);
        for (i in 0..len) {
            let community = vector::borrow(communities, i);
            if (community.community_id == community_id) {
                return i
            };
        };
        abort ECOMMUNITY_DOESNT_EXIST
    }

      // Function to find the post index by ID
  public(friend) fun find_post_index(posts: &vector<Post>, post_id: vector<u8>): u64 {
        let len = vector::length(posts);
        for (i in 0..len) {
            let post = vector::borrow(posts, i);
            if (post.id == post_id) {
                return i
            };
        };
        abort E_NOT_FOUND
    }

    fun is_user_a_member(members: &vector<address>, user_address: address): bool {
    let len = vector::length(members);
    for (i in 0..len) {
        if (*vector::borrow(members, i) == user_address) {
            return true
        };
    };
    return false
}

      #[test_only]
    public fun init_module_for_test(sender: &signer) {
        init_module(sender);
    }
}
