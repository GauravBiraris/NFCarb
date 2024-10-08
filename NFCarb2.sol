// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseContracts.sol";

contract NFCarb2 is ERC721, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for int256;

    enum CreditType {
        Fixation,
        ReducedEmission,
        Other
    }

    Counters.Counter private _tokenIdCounter;

    // Struct to hold metadata for each token
    struct CarbonCredit {
        CreditType creditType;
        int256 longitude;
        int256 latitude;
        uint256 startDate;
        uint256 endDate;
        uint256 co2Equivalent;
        string species;
        uint256 age;
        uint256 area;
        uint256 volume;
        bool verified;
        bool transferLocked;
    }

    // Mapping from token ID to CarbonCredit data
    mapping(uint256 => CarbonCredit) private _carbonCredits;

    // Mapping to track unique combinations of type, location, and time period
    mapping(bytes32 => bool) private _uniqueCredits;

    // Event for minting a new carbon credit
    event CarbonCreditMinted(
        uint256 indexed tokenId,
        int256 longitude,
        int256 latitude,
        uint256 startDate,
        uint256 endDate,
        uint256 co2Equivalent
    );

    // Event for verification status change
    event VerificationStatusChanged(uint256 indexed tokenId, bool verified);

    constructor() ERC721("NFCarb2", "NFC") Ownable() {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintCarbonCredit(
        address to,
        CreditType creditType,
        int256 longitude,
        int256 latitude,
        uint256 startDate,
        uint256 endDate,
        uint256 co2Equivalent,
        string memory species,
        uint256 age,
        uint256 area,
        uint256 volume
    ) public whenNotPaused returns (uint256) {
        require(startDate < endDate, "Invalid date range");

        bytes32 uniqueKey = keccak256(
            abi.encodePacked(
                uint8(creditType),
                longitude,
                latitude,
                startDate,
                endDate
            )
        );
        require(
            !_uniqueCredits[uniqueKey],
            "Credit with these parameters already exists"
        );

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        _carbonCredits[tokenId] = CarbonCredit({
            creditType: creditType,
            longitude: longitude,
            latitude: latitude,
            startDate: startDate,
            endDate: endDate,
            co2Equivalent: co2Equivalent,
            species: species,
            age: age,
            area: area,
            volume: volume,
            verified: false,
            transferLocked: false
        });

        _uniqueCredits[uniqueKey] = true;

        emit CarbonCreditMinted(
            tokenId,
            longitude,
            latitude,
            startDate,
            endDate,
            co2Equivalent
        );

        return tokenId;
    }

    function lockTransfer(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _carbonCredits[tokenId].transferLocked = true;
    }

    function addVerificationID(
        uint256 tokenId,
        bool verificationStatus
    ) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _carbonCredits[tokenId].verified = verificationStatus;
        emit VerificationStatusChanged(tokenId, verificationStatus);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        CarbonCredit memory credit = _carbonCredits[tokenId];

        string memory creditTypeString;
        if (credit.creditType == CreditType.Fixation) {
            creditTypeString = "Fixation";
        } else if (credit.creditType == CreditType.ReducedEmission) {
            creditTypeString = "ReducedEmission";
        } else {
            creditTypeString = "Other";
        }

        return
            string(
                abi.encodePacked(
                    credit.verified ? "true" : "false",
                    "~",
                    creditTypeString,
                    "~",
                    credit.longitude.toString(),
                    "~",
                    credit.longitude.toString(),
                    "~",
                    credit.latitude.toString(),
                    "~",
                    credit.startDate.toString(),
                    "~",
                    credit.endDate.toString(),
                    "~",
                    credit.co2Equivalent.toString()
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal whenNotPaused {
        require(
            !_carbonCredits[tokenId].transferLocked,
            "Token is locked and cannot be transferred"
        );

        _beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
