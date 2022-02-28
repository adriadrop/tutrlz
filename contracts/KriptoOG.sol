// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './KriptoOGLibrary.sol';
import './Base64.sol';

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
    }

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

    function setPupils(Coordinates[4] memory coordinates) private {
        for (uint8 i = 0; i < coordinates.length; i++) {
            pupils.push(coordinates[i]);
        }
    }

    function setWingType(uint48 wingTypeIndex, Coordinates[3] memory coordinates) private {
        for (uint8 i = 0; i < coordinates.length; i++) {
            wingTypes[wingTypeIndex].push(coordinates[i]);
        }
    }

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

    constructor(address _proxyRegistryAddress) ERC721('Kripto OGs', 'Original') {
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
                Color({ hexCode: '#bcdfb9', name: 'Green' }),
                Color({ hexCode: '#d5bada', name: 'Purple' }),
                Color({ hexCode: '#ecc1db', name: 'Pink' }),
                Color({ hexCode: '#e3c29e', name: 'Orange' }),
                Color({ hexCode: '#9cd7d5', name: 'Turquoise' }),
                Color({ hexCode: '#faf185', name: 'Yellow' }),
                Color({ hexCode: '#b0d9f4', name: 'Blue' }),
                Color({ hexCode: '#333333', name: 'Black' })
            ]
        );


        // Pupils
        setPupils(
            [
                Coordinates({ x: '16', y: '10' }),
                Coordinates({ x: '17', y: '10' }),
                Coordinates({ x: '16', y: '11' }),
                Coordinates({ x: '17', y: '11' })
            ]
        );

        // Regular
        setWingType(
            0,
            [Coordinates({ x: '0', y: '0' }), Coordinates({ x: '0', y: '0' }), Coordinates({ x: '0', y: '0' })]
        );


    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function weightedRarityGenerator(uint16 pseudoRandomNumber, uint8 trait) private view returns (uint16) {
        uint16 lowerBound = 0;

        for (uint8 i = 0; i < traitWeights[trait].length; i++) {
            uint16 weight = traitWeights[trait][i];

            if (pseudoRandomNumber >= lowerBound && pseudoRandomNumber < lowerBound + weight) {
                return i;
            }

            lowerBound = lowerBound + weight;
        }

        revert();
    }

    // We just set pseudo random numbers here into struct. According to those numbers we can then render something

    function createTokenIdOriginal(uint256 tokenId) public view returns (Original memory) {
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId)));

        return
            Original({
                backgroundColor: uint16(uint16(pseudoRandomBase) % 8),
                originalHead: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 1) % maxSupply), 0),
                originalBody: weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 2) % maxSupply), 1)
            });
    }

    function getOriginalBackground(Original memory original) private view returns (string memory OriginalBG) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    backgroundColors[original.backgroundColor].hexCode,
                    "' height='32' width='32' />"
                )
            );
    }

    function getOriginalBody(Original memory original) private view returns (string memory turtleWings) {
        turtleWings = string(
            abi.encodePacked(
                "<rect fill='",
                wingColors[original.wingColor].hexCode,
                "' height='1' width='6' x='5' y='8' />",
                "<rect fill='",
                wingColors[original.wingColor].hexCode,
                "' height='1' width='4' x='7' y='9' />",
                "<rect fill='",
                wingColors[original.wingColor].hexCode,
                "' height='1' width='2' x='9' y='10' />"
            )
        );

        // Regular wings don't need detail
        if (original.wingType != 0) {
            for (uint8 i = 0; i < wingTypes[original.wingType].length; i++) {
                turtleWings = string(
                    abi.encodePacked(
                        turtleWings,
                        "<rect fill='",
                        wingColors[original.wingColor].hexCode,
                        "' height='1' width='1' x='",
                        wingTypes[original.wingType][i].x,
                        "' y='",
                        wingTypes[original.wingType][i].y,
                        "' />"
                    )
                );
            }
        }

        return turtleWings;
    }

    function getOriginalHead(Original memory original) private view returns (string memory turtlePupil) {
        return
            string(
                abi.encodePacked(
                    "<rect fill='",
                    turtleTypes[original.turtleType].pupilHexCode,
                    "' height='1' width='1' x='",
                    pupils[original.pupil].x,
                    "' y='",
                    pupils[original.pupil].y,
                    "' />"
                )
            );
    }

    function getTokenIdOriginal(Original memory original) public view returns (string memory svg) {
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
                    "<svg id='kripto-ogs' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 32 32'>",
                    svg,
                    '<style>#kripto-ogs{shape-rendering:crispedges;}</style></svg>'
                )
            );
    }



    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        Original memory original = tokenIdOriginal[tokenId];

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Kripto OGs #',
                                    KriptoOGLibrary.toString(tokenId),
                                    '", "description": "Kripto OGs are a collection of fully on-chain, randomly generated, cryptocurrency original gangsters.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(getTokenIdOriginal(original))),
                                    '","attributes":'
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function internalMint(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, 'Quantity must be greater than 0.');
        require(numberOfTokens < 11, 'Exceeds max per mint.');
        require(totalSupply() + numberOfTokens <= maxSupply, 'Exceeds max supply.');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _nextTokenId.current();

            tokenIdOriginal[tokenId] = createTokenIdOriginal(tokenId);
            _safeMint(msg.sender, tokenId);
            _nextTokenId.increment();
        }
    }

    function ownerClaim(uint256 numberOfTokens) external onlyOwner {
        internalMint(numberOfTokens);
    }


    function mint(uint256 numberOfTokens) external payable {
        require(mintActive, 'Mint not active yet.');
        require(msg.value >= numberOfTokens * originalPrice, 'Wrong ETH value sent.');

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

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
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
        require(totalSupply() < maxSupply, 'All minted.');
        maxSupply = totalSupply();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
