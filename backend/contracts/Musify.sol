// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DecentralizedMusicPlatform {
    
    // Structure to hold details of each music track
    struct Music {
        string title;
        string artist;
        string genre;
        uint256 price; // Price to subscribe to the track in Wei
        address payable artistAddress;
        uint256 totalListeners;
        uint256 totalRating;
        uint256 ratingCount;
        bool isAvailable;
        string proofOfOwnership; // Hash or metadata proving ownership
    }

    // Structure to track user data
    struct User {
        uint256 reputation; // User's reputation score
        mapping(uint256 => bool) hasSubscribed; // Subscriptions for each track
    }

    // Mapping to store music by trackId
    mapping(uint256 => Music) public musicLibrary;
    
    // Mapping to store user data
    mapping(address => User) public users;

    // Counter to generate unique track IDs
    uint256 public nextTrackId = 1;

    // Events
    event MusicUploaded(uint256 trackId, string title, string artist, uint256 price, address artistAddress);
    event MusicListened(uint256 trackId, address listener, uint256 amountPaid);
    event TrackRated(uint256 trackId, address listener, uint8 rating);
    event TrackRemoved(uint256 trackId, address artist);

    // Modifier to ensure only the artist can perform certain actions
    modifier onlyArtist(uint256 _trackId) {
        require(musicLibrary[_trackId].artistAddress == msg.sender, "Only the artist can perform this action.");
        _;
    }

    // Modifier to ensure the track is available
    modifier trackAvailable(uint256 _trackId) {
        require(musicLibrary[_trackId].isAvailable, "This track is not available.");
        _;
    }

    // Function for artists to upload their music with proof of ownership
    function uploadMusic(
        string memory _title,
        string memory _artist,
        string memory _genre,
        uint256 _price,
        string memory _proofOfOwnership
    ) external {
        require(_price > 0, "Price should be greater than 0");
        require(bytes(_proofOfOwnership).length > 0, "Proof of ownership is required");

        uint256 trackId = nextTrackId;
        nextTrackId++;

        musicLibrary[trackId] = Music({
            title: _title,
            artist: _artist,
            genre: _genre,
            price: _price,
            artistAddress: payable(msg.sender),
            totalListeners: 0,
            totalRating: 0,
            ratingCount: 0,
            isAvailable: true,
            proofOfOwnership: _proofOfOwnership
        });

        emit MusicUploaded(trackId, _title, _artist, _price, msg.sender);
    }

    // Function for users to subscribe to a track (No streaming, only payments)
    function subscribeToMusic(uint256 _trackId) external payable trackAvailable(_trackId) {
        Music storage track = musicLibrary[_trackId];
        require(msg.value == track.price, "Incorrect payment amount.");
        require(!users[msg.sender].hasSubscribed[_trackId], "Already subscribed.");

        // Mark the user as subscribed
        users[msg.sender].hasSubscribed[_trackId] = true;

        // Pay the artist directly
        track.artistAddress.transfer(msg.value);

        // Emit the event for listening (but no actual streaming mechanism)
        emit MusicListened(_trackId, msg.sender, msg.value);
    }

    // Function to rate a track (1-5 stars)
    function rateTrack(uint256 _trackId, uint8 _rating) external trackAvailable(_trackId) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(users[msg.sender].hasSubscribed[_trackId], "You must be subscribed to rate this track.");

        Music storage track = musicLibrary[_trackId];

        track.totalRating += _rating;
        track.ratingCount++;

        uint256 averageRating = track.totalRating / track.ratingCount;
        users[track.artistAddress].reputation = averageRating;

        emit TrackRated(_trackId, msg.sender, _rating);
    }

    // Function to remove a music track (No Refunds for users)
    function removeMusic(uint256 _trackId) external onlyArtist(_trackId) {
        musicLibrary[_trackId].isAvailable = false;
        emit TrackRemoved(_trackId, msg.sender);
    }

    // Function to verify proof of ownership
    function getProofOfOwnership(uint256 _trackId) external view returns (string memory) {
        return musicLibrary[_trackId].proofOfOwnership;
    }

    // Function to get the reputation of a user
    function getUserReputation(address _user) external view returns (uint256) {
        return users[_user].reputation;
    }

    // Function to get the average rating of a track
    function getTrackAverageRating(uint256 _trackId) external view returns (uint256) {
        Music storage track = musicLibrary[_trackId];
        if (track.ratingCount == 0) return 0;
        return track.totalRating / track.ratingCount;
    }

    // Receive function to accept payments
    receive() external payable {}
}
