// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

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

    // Event to emit when a track is uploaded
    event MusicUploaded(uint256 trackId, string title, string artist, uint256 price, address artistAddress);

    // Event to emit when a track is listened to
    event MusicListened(uint256 trackId, address listener, uint256 amountPaid);

    // Event to emit when a track is rated
    event TrackRated(uint256 trackId, address listener, uint8 rating);

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

    // Function for artists to upload their music
    function uploadMusic(
        string memory _title,
        string memory _artist,
        string memory _genre,
        uint256 _price
    ) external {
        require(_price > 0, "Price should be greater than 0");

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
            isAvailable: true
        });

        emit MusicUploaded(trackId, _title, _artist, _price, msg.sender);
    }

    // Function for users to subscribe to a track
    function subscribeToMusic(uint256 _trackId) external payable trackAvailable(_trackId) {
        Music storage track = musicLibrary[_trackId];
        require(msg.value == track.price, "Incorrect payment amount.");
        require(!users[msg.sender].hasSubscribed[_trackId], "Already subscribed.");

        // Mark the user as subscribed
        users[msg.sender].hasSubscribed[_trackId] = true;

        // Pay the artist in one transaction
        track.artistAddress.transfer(msg.value);

        // Emit the event for listening
        emit MusicListened(_trackId, msg.sender, msg.value);
    }

    // Function to rate a track (1-5 stars)
    function rateTrack(uint256 _trackId, uint8 _rating) external trackAvailable(_trackId) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(users[msg.sender].hasSubscribed[_trackId], "You must be subscribed to rate this track.");

        Music storage track = musicLibrary[_trackId];

        track.totalRating += _rating;
        track.ratingCount++;

        // Optionally, you could update the artist's reputation based on the average rating
        uint256 averageRating = track.totalRating / track.ratingCount;
        users[track.artistAddress].reputation = averageRating;

        emit TrackRated(_trackId, msg.sender, _rating);
    }

    // Function to list available tracks (view function, no state changes)
    function getAvailableTracks() external view returns (Music[] memory availableTracks) {
        uint256 trackCount = nextTrackId - 1; // Exclude track ID 0
        uint256 availableCount = 0;

        for (uint256 i = 1; i <= trackCount; i++) {
            if (musicLibrary[i].isAvailable) {
                availableCount++;
            }
        }

        availableTracks = new Music[](availableCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= trackCount; i++) {
            if (musicLibrary[i].isAvailable) {
                availableTracks[index] = musicLibrary[i];
                index++;
            }
        }
    }

    // Function to remove a music track (only the artist can do this)
    function removeMusic(uint256 _trackId) external onlyArtist(_trackId) {
        musicLibrary[_trackId].isAvailable = false;
    }

    // Function to get the reputation of a user
    function getUserReputation(address _user) external view returns (uint256) {
        return users[_user].reputation;
    }

    // Fallback function to receive Ether (if any user sends directly to the contract)
    receive() external payable {}

    // Helper function to get the average rating of a track
    function getTrackAverageRating(uint256 _trackId) external view returns (uint256) {
        Music storage track = musicLibrary[_trackId];
        if (track.ratingCount == 0) return 0;
        return track.totalRating / track.ratingCount;
    }
}
