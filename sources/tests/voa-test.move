module my_addrx::tests {
    use my_addrx::Community;
    use std::vector;
    use std::debug;

    // Define some custom error codes
    const E_COMMUNITY_NOT_CREATED: u64 = 1;
    const E_POST_NOT_CREATED: u64 = 2;
    const E_PROPOSAL_NOT_CREATED: u64 = 3;
    const E_COMMUNITY_NOT_FOUND: u64 = 4;
    const E_POST_NOT_FOUND: u64 = 5;
    const E_MEMBER_NOT_ADDED: u64 = 6;
    const E_MEMBER_NOT_REMOVED: u64 = 6;

 #[test(account=@0xabc)]
    public fun test_create_community(account: &signer) {
        Community::init_module_for_test(account);
        let community_id = b"community1";
        
        // Create a community
        Community::create_community(account, 
            community_id,
            1,  // min_voice_power_post
            1,  // min_voice_age_post
            1,  // min_voice_power_comment
            1,  // min_voice_age_comment
            1,  // min_voice_power_proposal
            1,  // min_voice_age_proposal
            1,  // min_voice_power_poll
            1   // min_voice_age_poll
        );

        // Verify that the community was created
 // Use the getter function to retrieve communities
    let communities = Community::get_communities(account);
        assert!(vector::length(&communities) == 1, E_COMMUNITY_NOT_CREATED);
    }

 #[test(account=@0xabc)]
    public fun test_create_post(account: &signer) {
        Community::init_module_for_test(account);
        let community_id = b"community1";
        Community::create_community(account, 
            community_id,
            1, 1, 1, 1, 1, 1, 1, 1);
        
        let post_id = b"post1";
        let content = b"This is a post";
        
        // Create a post
        Community::create_post(account, community_id, post_id, content);

        // Verify that the post was created
        // Use the getter function to retrieve communities
    let communities = Community::get_communities(account);
        let community = vector::borrow(&communities, 0);
          let posts = Community::get_posts(community);
        assert!(vector::length(posts) == 1, E_POST_NOT_CREATED);
    }

 #[test(account=@0xabc)]
    public fun test_create_proposal(account: &signer) {
        Community::init_module_for_test(account);
        let community_id = b"community1";
        Community::create_community(account, 
            community_id,
            1, 1, 1, 1, 1, 1, 1, 1);
        
        let proposal_id = b"proposal1";
        let title = b"Proposal Title";
        let description = b"Proposal Description";
        
        // Create a proposal
        Community::create_proposal(account, community_id, proposal_id, title, description);

        // Verify that the proposal was created
    let communities = Community::get_communities(account);
        let community = vector::borrow(&communities, 0);
        let proposals = Community::get_proposals(community);
        assert!(vector::length(proposals) == 1, E_PROPOSAL_NOT_CREATED);
    }

 #[test(account=@0xabc)]
    public fun test_find_community_index(account: &signer) {
        Community::init_module_for_test(account);
        let community_id = b"community1";
        Community::create_community(account, 
            community_id,
            1, 1, 1, 1, 1, 1, 1, 1);
        
 // Use the getter function to retrieve communities
    let communities = Community::get_communities(account);
        
        // Test for existing community
        let community_index = Community::find_community_index(&communities, community_id);
        assert!(community_index == 0, E_COMMUNITY_NOT_FOUND);

        // Test for non-existing community (should abort with error)
        // let non_existing_id = b"community2";
        // assert!(Community::find_community_index(&communities, non_existing_id) == 0, E_COMMUNITY_NOT_FOUND);
    }

    //test for join community
    #[test(account=@0xabc)]
    public fun test_join_comunity(account: &signer){
           Community::init_module_for_test(account);
           let community_id = b"community1";

               Community::create_community(account, 
            community_id,
            1, 1, 1, 1, 1, 1, 1, 1);

           Community::join_community(account, community_id);

        // Verify that the member was added to the community
        let communities = Community::get_communities(account);
        let community = vector::borrow(&communities, 0);

        let members = Community::get_members(community);
        assert!(vector::length(members) == 1, E_MEMBER_NOT_ADDED);
    }

    //test for leave community
    #[test(account=@0xabc)]
    public fun test_leave_comunity(account: &signer){
           Community::init_module_for_test(account);
           let community_id = b"community1";

               Community::create_community(account, 
            community_id,
            1, 1, 1, 1, 1, 1, 1, 1);

              Community::join_community(account, community_id);

           Community::leave_community(account, community_id);

        // Verify that the member was removed to the community
        let communities = Community::get_communities(account);
        let community = vector::borrow(&communities, 0);

        let members = Community::get_members(community);
        assert!(vector::length(members) == 0, E_MEMBER_NOT_REMOVED);
    }

    // Update other tests similarly...
}
