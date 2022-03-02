// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./KriptoOGLibrary.sol";
import "./Base64.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract KriptoOG is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    uint256 public maxSupply = 5000;
    uint256 public originalPrice = 0.02 ether;

    bool public claimActive = true;
    bool public mintActive = true;

    struct Original {
        uint16 backgroundColor;
        uint16 originalHead;
        uint16 originalBody;
        string originalName;
    }

    string[] public bodies;
    string[] public heads;
    string[] public names;

    struct Coordinates {
        string x;
        string y;
    }

    struct Color {
        string hexCode;
        string name;
    }

    mapping(uint256 => Original) private tokenIdOriginal;

    Color[] private backgroundColors;

    uint16[][6] private traitWeights;

    address public immutable proxyRegistryAddress;
    bool public openSeaProxyActive;
    mapping(address => bool) public proxyToApproved;

    function setBackgroundColors(Color[8] memory colors) private {
        for (uint8 i = 0; i < colors.length; i++) {
            backgroundColors.push(colors[i]);
        }
    }

    function toggleOpenSeaProxy() public onlyOwner {
        openSeaProxyActive = !openSeaProxyActive;
    }

    function toggleProxy(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    constructor(address _proxyRegistryAddress)
        ERC721("Kripto OGs", "Original")
    {
        // Start at token 1
        _nextTokenId.increment();

        // Wing type rarity
        traitWeights[0] = [1248, 986, 842, 724, 569, 371, 209, 51];

        // Wing color rarity
        traitWeights[1] = [3200, 1200, 500, 100];

        // Boots rarity
        traitWeights[2] = [1622, 3378];

        // OpenSea proxy contract
        proxyRegistryAddress = _proxyRegistryAddress;

        // Background colors
        setBackgroundColors(
            [
                Color({hexCode: "#bcdfb9", name: "Green"}),
                Color({hexCode: "#d5bada", name: "Purple"}),
                Color({hexCode: "#ecc1db", name: "Pink"}),
                Color({hexCode: "#e3c29e", name: "Orange"}),
                Color({hexCode: "#9cd7d5", name: "Turquoise"}),
                Color({hexCode: "#faf185", name: "Yellow"}),
                Color({hexCode: "#b0d9f4", name: "Blue"}),
                Color({hexCode: "#333333", name: "Black"})
            ]
        );

        names = [
            "Bliss",
            "Telasius",
            "High Priest",
            "Vukman",
            "Seljo beljo",
            "Ojdanic",
            "Skoric",
            "Skvorcer",
            "d_K",
            "Zord4n",
            "nodmme",
            "Marko",
            "Trolcina",
            "Putin",
            "Plenkovic"
        ];

        bodies = [
            '<path stroke="#000000" d="M10,21h1M19,21h1M10,22h2M19,22h1M10,23h3M18,23h2M10,24h4M17,24h3M10,25h2M19,25h1"/><path stroke="#fb922b" d="M9,22h1M20,22h1M7,23h3M20,23h2M5,24h5M20,24h4M4,25h6M12,25h2M17,25h2M20,25h6M3,26h24M3,27h24M3,28h24M3,29h24M3,30h24M3,31h24" />',
            '<path stroke="#193d3f" d="M10,21h1M19,21h1M10,22h2M19,22h1M10,23h3M18,23h2M10,24h4M17,24h3M10,25h2M19,25h1"/><path stroke="#63c64d" d="M9,22h1M8,23h2M21,23h1M5,24h1M8,24h2M21,24h2M4,25h2M8,25h2M12,25h2M17,25h2M21,25h2M25,25h1M4,26h2M8,26h2M12,26h2M17,26h2M21,26h2M25,26h2M4,27h2M8,27h2M12,27h2M17,27h2M21,27h2M25,27h2M4,28h2M8,28h2M12,28h2M17,28h2M21,28h2M25,28h2M4,29h2M8,29h2M12,29h2M17,29h2M21,29h2M25,29h2M4,30h2M8,30h2M12,30h2M17,30h2M21,30h2M25,30h2M4,31h2M8,31h2M12,31h2M17,31h2M21,31h2M25,31h2"/><path stroke="#1bb158" d="M20,22h1M7,23h1M20,23h1M6,24h2M20,24h1M23,24h1M6,25h2M20,25h1M23,25h2M3,26h1M6,26h2M10,26h2M14,26h3M19,26h2M23,26h2M3,27h1M6,27h2M10,27h2M14,27h3M19,27h2M23,27h2M3,28h1M6,28h2M10,28h2M14,28h3M19,28h2M23,28h2M3,29h1M6,29h2M10,29h2M14,29h3M19,29h2M23,29h2M3,30h1M6,30h2M10,30h2M14,30h3M19,30h2M23,30h2M3,31h1M6,31h2M10,31h2M14,31h3M19,31h2M23,31h2"/>',
            '<path stroke="#0484d1" d="M10,21h1M19,21h1M9,22h3M19,22h2M10,23h3M18,23h2M11,24h3M17,24h3M12,25h2M17,25h2M13,26h5"/><path stroke="#ffffff" d="M7,23h3M20,23h2M5,24h6M20,24h4M4,25h8M19,25h7M3,26h10M18,26h9M3,27h24M3,28h24M3,29h24M3,30h24M3,31h24"/>',
            '<path stroke="#ffffff" d="M10,21h1M19,21h1M10,22h2M19,22h1M10,23h3M18,23h2M10,24h4M17,24h3M10,25h2M19,25h1"/><path stroke="#001155" d="M9,22h1M20,22h1M7,23h3M20,23h2M5,24h5M20,24h4M4,25h6M12,25h2M17,25h2M20,25h6M3,26h24M3,27h24M3,28h24M3,29h24M3,30h24M3,31h24"/>'
        ];

        heads = [
            '<path stroke="#f1cba8" d="M13,5h5M12,6h7M11,7h1M16,7h4M11,8h1M17,8h1M19,8h2M10,9h2M19,9h2M10,10h1M19,10h2M10,11h1M12,11h1M20,11h1M10,12h1M20,12h1M10,13h2M20,13h1M11,14h3M10,15h1M10,16h1M14,16h4M10,17h3M19,18h1M13,19h2M17,19h2"/><path stroke="#f8d9be" d="M12,7h4M12,8h5M18,8h1M12,9h7M11,10h8M11,11h1M11,12h3M15,12h1M17,12h1M19,12h1M12,13h4M17,13h3M10,14h1M14,14h2M18,14h3M11,15h5M18,15h2M11,16h2M19,16h1M19,17h1M12,18h1M11,20h1M14,20h4M11,21h2M12,22h7M13,23h2M16,23h2M14,24h1M16,24h1M14,25h3"/><path stroke="#1b171a" d="M13,11h3M17,11h3"/><path stroke="#e3be9c" d="M16,11h1M15,19h2"/><path stroke="#000000" d="M14,12h1M18,12h1"/><path stroke="#fb922b" d="M16,12h1M16,13h1M16,14h1M16,15h1"/><path stroke="#d2af8f" d="M8,13h1M21,13h1M13,16h1M18,16h1M13,17h1M18,17h1M11,18h1M13,18h1M18,18h1M11,19h2M19,19h1M12,20h2M18,20h1M13,21h6"/><path stroke="#ebbf95" d="M9,13h1M8,14h2M21,14h1M8,15h1M21,15h1"/><path stroke="#fea751" d="M17,14h1M17,15h1"/><path stroke="#e4a672" d="M9,15h1M20,15h1"/><path stroke="#ffffff" d="M14,17h4"/><path stroke="#e1a598" d="M14,18h4"/><path stroke="#c89979" d="M15,23h1M15,24h1"/>',
            '<path stroke="#ebbf95" d="M11,5h8M10,6h10M9,7h4M16,7h5M9,8h3M19,8h2M9,9h2M20,9h1M9,10h2M20,10h1M9,11h3M20,11h1M9,12h2M20,12h1M9,14h1M20,14h1M9,15h1M20,15h1"/><path stroke="#f8d9be" d="M13,7h3M12,8h7M11,9h9M11,10h9M12,11h1M16,11h1M11,12h3M15,12h1M17,12h1M19,12h1M8,13h8M17,13h5M8,14h1M10,14h6M17,14h3M21,14h1M8,15h1M10,15h6M17,15h3M21,15h1M10,16h3M19,16h1M10,17h3M19,17h1M12,18h1M11,20h1M14,20h4M11,21h2M12,22h7M13,23h5M14,24h3M14,25h3"/><path stroke="#1b171a" d="M13,11h3M17,11h3"/><path stroke="#743f39" d="M14,12h1M18,12h1"/><path stroke="#fb922b" d="M16,12h1M16,13h1M16,14h1M16,15h1"/><path stroke="#f1cba8" d="M13,16h6M13,17h1M18,17h1M11,18h1M13,18h1M18,18h2M11,19h9M12,20h2M18,20h1M13,21h6"/><path stroke="#ffffff" d="M14,17h4"/><path stroke="#e1a598" d="M14,18h4"/>',
            '<path stroke="#ebbf95" d="M11,5h8M10,6h2M19,6h1M9,7h2M20,7h1M9,8h2M20,8h1M9,9h1M20,9h1M9,10h1M20,10h1M9,11h1M20,11h1M9,12h1M9,14h1M20,14h1"/><path stroke="#f1cba8" d="M12,6h7M11,7h2M16,7h4M11,8h1M19,8h1M10,9h1M10,10h1M10,11h2M10,12h1M20,12h1M10,13h1M10,14h1M14,16h4M13,17h1M18,17h1M11,18h1M13,18h1M18,18h2M11,19h9M12,20h2M18,20h1M13,21h2M17,21h2M15,22h2M15,23h1M15,24h1M15,25h1"/><path stroke="#f8d9be" d="M13,7h3M12,8h7M11,9h9M11,10h9M12,11h1M16,11h1M11,12h3M15,12h1M17,12h1M19,12h1M8,13h2M11,13h5M17,13h5M8,14h1M11,14h5M17,14h3M21,14h1M8,15h8M17,15h5M10,16h4M18,16h2M10,17h3M19,17h1M12,18h1M14,18h4M11,20h1M14,20h4M11,21h2M15,21h2M12,22h3M17,22h2M13,23h2M16,23h2M14,24h1M16,24h1M14,25h1M16,25h1"/><path stroke="#1b171a" d="M13,11h3M17,11h3"/><path stroke="#0484d1" d="M14,12h1M18,12h1"/><path stroke="#fb922b" d="M16,12h1M16,13h1M16,14h1M16,15h1"/><path stroke="#ca9c92" d="M14,17h4"/>',
            '<path stroke="#925851" d="M11,5h8M10,6h10M9,7h4M16,7h5M9,8h3M19,8h2M9,9h2M20,9h1M9,10h2M20,10h1M9,11h3M20,11h1M9,12h2M12,12h2M19,12h2M15,13h1M17,13h1M12,14h4M17,14h3M11,15h2M19,15h1M14,20h4M15,21h2M15,23h1M15,24h1"/><path stroke="#7c4f4a" d="M13,7h3M12,8h7M11,9h9M11,10h9M12,11h1M16,11h1M11,12h1M15,12h1M17,12h1M8,13h7M18,13h4M8,14h1M10,14h2M21,14h1M8,15h3M13,15h3M17,15h2M20,15h2M10,16h3M19,16h1M10,17h3M19,17h1M12,18h1M11,20h1M11,21h2M12,22h7M13,23h2M16,23h2M14,24h1M16,24h1M14,25h3"/><path stroke="#1b171a" d="M13,11h3M17,11h3"/><path stroke="#3f2832" d="M14,12h1M18,12h1M14,17h4"/><path stroke="#523733" d="M16,12h1M16,13h1M16,14h1M16,15h1"/><path stroke="#a1706a" d="M9,14h1M20,14h1"/><path stroke="#7c453f" d="M13,16h6M13,17h1M18,17h1M11,18h1M13,18h1M18,18h2M11,19h9M12,20h2M18,20h1M13,21h2M17,21h2"/><path stroke="#5a3a48" d="M14,18h4"/>',
            '<path stroke="#ebbf95" d="M11,5h8M10,6h10M9,7h4M16,7h5M9,8h3M19,8h2M9,9h2M20,9h1M9,10h2M20,10h1M9,11h3M20,11h1M9,12h2M9,14h1M20,14h1M9,15h1"/><path stroke="#f8d9be" d="M13,7h3M12,8h7M11,9h9M11,10h9M12,11h1M16,11h1M11,12h1M15,12h1M17,12h1M8,13h8M17,13h5M8,14h1M10,14h2M14,14h2M17,14h1M21,14h1M8,15h1M10,15h1M13,15h3M17,15h2M21,15h1M10,16h3M19,16h1M10,17h3M19,17h1M12,18h1M11,20h1M11,21h2M12,22h7M13,23h5M14,24h3M14,25h3"/><path stroke="#1b171a" d="M13,11h3M17,11h3"/><path stroke="#e4a672" d="M12,12h2M19,12h2M12,14h2M18,14h2M11,15h2M19,15h2M14,20h4M15,21h2"/><path stroke="#0484d1" d="M14,12h1M18,12h1"/><path stroke="#fb922b" d="M16,12h1M16,13h1M16,14h1M16,15h1"/><path stroke="#f1cba8" d="M13,16h6M13,17h1M18,17h1M11,18h1M13,18h1M18,18h2M11,19h9M12,20h2M18,20h1M13,21h2M17,21h2"/><path stroke="#ca9c92" d="M14,17h4"/><path stroke="#e1a598" d="M14,18h4"/>'
        ];
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function removeName(uint256 tokenId) public {
        Original memory original = tokenIdOriginal[tokenId];
        console.log(original.originalName);
        uint256 j;
            for (uint i = 0; i < names.length; i++) {
                if ( keccak256(bytes(original.originalName )) == keccak256(bytes(names[i])) ){
                        j = i;
                }
            }
        names[j] = names[names.length - 1];
        names.pop();
    }

    function weightedRarityGenerator(uint16 pseudoRandomNumber, uint8 trait)
        private
        view
        returns (uint16)
    {
        uint16 lowerBound = 0;

        for (uint8 i = 0; i < traitWeights[trait].length; i++) {
            uint16 weight = traitWeights[trait][i];

            if (
                pseudoRandomNumber >= lowerBound &&
                pseudoRandomNumber < lowerBound + weight
            ) {
                return i;
            }

            lowerBound = lowerBound + weight;
        }

        revert();
    }

    // We just set pseudo random numbers here into struct. According to those numbers we can then render something

    function createTokenIdOriginal(uint256 tokenId)
        public
        view
        returns (Original memory)
    {
        uint256 pseudoRandomBase = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return
            Original({
                backgroundColor: uint16(uint16(pseudoRandomBase) % 8),
                originalHead: uint16(uint16(pseudoRandomBase) % 5),
                originalBody: uint16(uint16(pseudoRandomBase) % 4),
                originalName: names[
                    uint16(uint16(pseudoRandomBase) % names.length)
                ]
            });
    }

    function getOriginalBackground(Original memory original)
        private
        view
        returns (string memory OriginalBG)
    {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    backgroundColors[original.backgroundColor].hexCode,
                    "' height='32' width='32' />"
                )
            );
    }

    function getOriginalBody(Original memory original)
        private
        view
        returns (string memory originalBody)
    {
        originalBody = string(abi.encodePacked(bodies[original.originalBody]));
        return originalBody;
    }

    function getOriginalHead(Original memory original)
        private
        view
        returns (string memory originalHead)
    {
        originalHead = string(abi.encodePacked(heads[original.originalHead]));
        return originalHead;
    }



    function getTokenIdOriginal(Original memory original)
        public
        view
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                getOriginalBackground(original),
                getOriginalBody(original),
                getOriginalHead(original)
            )
        );

        return
            string(
                abi.encodePacked(
                    "<svg id='kripto-ogs' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 -0.5 32 35'>",
                    svg,
                    "<rect y='31.5' fill='white' height='3' width='32' /><text x='50%' text-anchor='middle' y='34' fill='black' font-size='3'>",
                    original.originalName,
                    "</text><style>#kripto-ogs{shape-rendering:crispedges;}</style></svg>"
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId));
        Original memory original = tokenIdOriginal[tokenId];

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Kripto OGs #',
                                    KriptoOGLibrary.toString(tokenId),
                                    '", "description": "Kripto OGs are a collection of fully on-chain, randomly generated, cryptocurrency original gangsters.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(
                                        bytes(getTokenIdOriginal(original))
                                    ),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function internalMint(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens < 11, "Exceeds max per mint.");
        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Exceeds max supply."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _nextTokenId.current();

            tokenIdOriginal[tokenId] = createTokenIdOriginal(tokenId);
            removeName(tokenId);

            _safeMint(msg.sender, tokenId);
            _nextTokenId.increment();
        }
    }

    function ownerClaim(uint256 numberOfTokens) external onlyOwner {
        internalMint(numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable {
        require(mintActive, "Mint not active yet.");
        require(
            msg.value >= numberOfTokens * originalPrice,
            "Wrong ETH value sent."
        );

        internalMint(numberOfTokens);
    }

    function setOriginalsPrice(uint256 newOriginalPrice) external onlyOwner {
        originalPrice = newOriginalPrice;
    }

    function toggleClaim() external onlyOwner {
        claimActive = !claimActive;
    }

    function toggleMint() external onlyOwner {
        mintActive = !mintActive;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Allow OpenSea proxy contract
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (address(proxyRegistry.proxies(owner)) == operator) {
            return openSeaProxyActive;
        }

        // Allow future contracts
        if (proxyToApproved[operator]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function reduceSupply() external onlyOwner {
        require(totalSupply() < maxSupply, "All minted.");
        maxSupply = totalSupply();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
