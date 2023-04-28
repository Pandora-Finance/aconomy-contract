// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./utils/LibShare.sol";

contract piNFT is ERC721URIStorage, IERC721Receiver, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // tokenId => (token contract => balance)
    mapping(uint256 => mapping(address => uint256)) erc20Balances;

    // tokenId => token contract
    mapping(uint256 => address[]) erc20Contracts;

    // tokenId => royalties
    mapping(uint256 => LibShare.Share[]) public royaltiesByTokenId;

    mapping(uint256 => LibShare.Share[]) public royaltiesForValidator;

    // tokenId => (token contract => token contract index)
    mapping(uint256 => mapping(address => uint256)) erc20ContractIndex;

    // TokenId => Owner Address
    mapping(uint256 => address) NFTowner;

    // TokenId => Amount
    mapping(uint256 => uint256) withdrawnAmount;

    mapping(uint256 => address) public approvedValidator;

    event ERC20Added(
        address indexed _from,
        uint256 indexed _tokenId,
        address indexed _erc20Contract,
        uint256 _value
    );
    event ERC20Transferred(
        uint256 indexed _tokenId,
        address indexed _to,
        address indexed _erc20Contract,
        uint256 _value
    );
    event RoyaltiesSetForTokenId(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    event RoyaltiesSetForValidator(
        uint256 indexed tokenId,
        LibShare.Share[] royalties
    );

    event PiNFTRedeemed(
        uint256 tokenId,
        address nftReciever,
        address validatorAddress,
        address erc20Contract,
        uint256 value
    );

    event PiNFTBurnt(
        uint256 tokenId,
        address nftReciever,
        address erc20Receiver,
        address erc20Contract,
        uint256 value
    );

    event ValidatorFundsWithdrawn(
        address withdrawer,
        uint256 tokenId,
        address erc20Contract,
        uint256 amount
    );

    event ValidatorFundsRepayed(
        address repayer,
        uint256 tokenId,
        address erc20Contract,
        uint256 amount
    );

    event ValidatorAdded(uint256 tokenId, address validator);

    event TokenMinted(uint256 tokenId, address to);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "Only token owner can execute"
        );
        _;
    }

    // mints an ERC721 token to _to with _uri as token uri
    function mintNFT(
        address _to,
        string memory _uri,
        LibShare.Share[] memory royalties
    ) public returns (uint256) {
        require(_to != address(0));
        uint256 tokenId_ = _tokenIdCounter.current();
        _setRoyaltiesByTokenId(tokenId_, royalties);
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
        return tokenId_;
    }

    function _setRoyaltiesByTokenId(
        uint256 _tokenId,
        LibShare.Share[] memory royalties
    ) internal {
        require(royalties.length <= 10, "> 10");
        delete royaltiesByTokenId[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                "Royalty not present"
            );
            require(royalties[i].value != 0, "value 0");
            royaltiesByTokenId[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4000, "overflow");

        emit RoyaltiesSetForTokenId(_tokenId, royalties);
    }

    function getRoyalties(uint256 _tokenId)
        external
        view
        returns (LibShare.Share[] memory)
    {
        return royaltiesByTokenId[_tokenId];
    }

    function getValidatorRoyalties(uint256 _tokenId)
        external
        view
        returns (LibShare.Share[] memory)
    {
        return royaltiesForValidator[_tokenId];
    }

    function addValidator(uint256 _tokenId, address _validator)
        external
        onlyOwnerOfToken(_tokenId)
    {
        require(erc20Contracts[_tokenId].length == 0);
        approvedValidator[_tokenId] = _validator;
        emit ValidatorAdded(_tokenId, _validator);
    }

    // this function requires approval of tokens by _erc20Contract
    // adds ERC20 tokens to the token with _tokenId(basically trasnfer ERC20 to this contract)
    function addERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value,
        LibShare.Share[] memory royalties
    ) public {
        require(msg.sender == approvedValidator[_tokenId]);
        require(_erc20Contract != address(0));
        require(_value != 0);
        if(erc20Contracts[_tokenId].length >= 1) {
            require(_erc20Contract == erc20Contracts[_tokenId][0], "invalid");
        }
        NFTowner[_tokenId] = ERC721.ownerOf(_tokenId);
        updateERC20(_tokenId, _erc20Contract, _value);
        setRoyaltiesForValidator(_tokenId, royalties);
        require(
            IERC20(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _value
            ),
            "failed"
        );
        emit ERC20Added(msg.sender, _tokenId, _erc20Contract, _value);
    }

    // update the mappings for a token on recieving ERC20 tokens
    function updateERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(ERC721.ownerOf(_tokenId) != address(0));
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        if (erc20Balance == 0) {
            erc20ContractIndex[_tokenId][_erc20Contract] = erc20Contracts[
                _tokenId
            ].length;
            erc20Contracts[_tokenId].push(_erc20Contract);
        }
        erc20Balances[_tokenId][_erc20Contract] += _value;
    }

    //Set Royalties for Validator
    function setRoyaltiesForValidator(
        uint256 _tokenId,
        LibShare.Share[] memory royalties
    ) public {
        require(msg.sender == approvedValidator[_tokenId]);
        require(royalties.length <= 10, "> 10");
        delete royaltiesForValidator[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0));
            require(royalties[i].value != 0, "royalty 0");
            royaltiesForValidator[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4000, "overflow");

        emit RoyaltiesSetForValidator(_tokenId, royalties);
    }

    function deleteNFT(uint256 _tokenId) external nonReentrant {
        require(NFTowner[_tokenId] == address(0));
        require(ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
    }

    function redeemOrBurnPiNFT(
        uint256 _tokenId,
        address _nftReciever,
        address _erc20Reciever,
        address _erc20Contract,
        bool burnNFT
    ) external onlyOwnerOfToken(_tokenId) nonReentrant {
        require(approvedValidator[_tokenId] != address(0));
        require(_erc20Contract != address(0));
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        uint256 _value = erc20Balances[_tokenId][_erc20Contract];
        if(burnNFT) {
            require(_erc20Reciever != address(0));
            require(_nftReciever == address(0));
            _transferERC20(_tokenId, _erc20Reciever, _erc20Contract, _value);
            ERC721.safeTransferFrom(msg.sender, approvedValidator[_tokenId], _tokenId);

            emit PiNFTBurnt(
            _tokenId,
            approvedValidator[_tokenId],
            _erc20Reciever,
            _erc20Contract,
            _value
            );
        } else {
            require(_nftReciever != address(0));
            require(_erc20Reciever == address(0));
            _transferERC20(_tokenId, approvedValidator[_tokenId], _erc20Contract, _value);
            if (msg.sender != _nftReciever) {
            ERC721.safeTransferFrom(msg.sender, _nftReciever, _tokenId);
            }

            emit PiNFTRedeemed(
            _tokenId,
            _nftReciever,
            approvedValidator[_tokenId],
            _erc20Contract,
            _value
            );
        }
        approvedValidator[_tokenId] = address(0);
        NFTowner[_tokenId] = address(0);
        delete royaltiesForValidator[_tokenId];
    }

    // transfers the ERC 20 tokens from _tokenId(this contract) to _to address
    function _transferERC20(
        uint256 _tokenId,
        address _to,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(_to != address(0));
        removeERC20(_tokenId, _erc20Contract, _value);
        require(IERC20(_erc20Contract).transfer(_to, _value), "failed");
        emit ERC20Transferred(_tokenId, _to, _erc20Contract, _value);
    }

    // update the mappings for a token when ERC20 tokens gets removed
    function removeERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        require(erc20Balance >= _value);
        uint256 newERC20Balance = erc20Balance - _value;
        erc20Balances[_tokenId][_erc20Contract] = newERC20Balance;
        if (newERC20Balance == 0) {
            uint256 lastContractIndex = erc20Contracts[_tokenId].length - 1;
            address lastContract = erc20Contracts[_tokenId][lastContractIndex];
            if (_erc20Contract != lastContract) {
                uint256 contractIndex = erc20ContractIndex[_tokenId][
                    _erc20Contract
                ];
                erc20Contracts[_tokenId][contractIndex] = lastContract;
                erc20ContractIndex[_tokenId][lastContract] = contractIndex;
            }
            delete erc20ContractIndex[_tokenId][_erc20Contract];
            erc20Contracts[_tokenId].pop();
        }
    }

    // view ERC 20 token balance of a token
    function viewBalance(uint256 _tokenId, address _erc20Address)
        public
        view
        returns (uint256)
    {
        return erc20Balances[_tokenId][_erc20Address];
    }

    function withdraw(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant {
        if(withdrawnAmount[_tokenId] == 0) {
            require(msg.sender == ownerOf(_tokenId));
            NFTowner[_tokenId] = msg.sender;
        }
        require(NFTowner[_tokenId] == msg.sender, "not owner");
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(
            withdrawnAmount[_tokenId] + _amount <=
                erc20Balances[_tokenId][_erc20Contract]
        );
        require(
            IERC20(_erc20Contract).transfer(msg.sender, _amount),
            "failed"
        );

        //needs approval on frontend
        // transferring NFT to this address
        if (withdrawnAmount[_tokenId] == 0) {
            ERC721.safeTransferFrom(msg.sender, address(this), _tokenId);
        }

        withdrawnAmount[_tokenId] += _amount;
        emit ValidatorFundsWithdrawn(
            msg.sender,
            _tokenId,
            _erc20Contract,
            _amount
        );
    }

    function viewWithdrawnAmount(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return withdrawnAmount[_tokenId];
    }

    function Repay(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant {
        require(NFTowner[_tokenId] == msg.sender);
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(_amount <= withdrawnAmount[_tokenId]);
        // Send payment to the Pool
        require(
            IERC20(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "failed"
        );
        withdrawnAmount[_tokenId] -= _amount;

        if (withdrawnAmount[_tokenId] == 0) {
            ERC721(address(this)).approve(msg.sender, _tokenId);
            ERC721.safeTransferFrom(address(this), msg.sender, _tokenId);
        }
        emit ValidatorFundsRepayed(
            msg.sender,
            _tokenId,
            _erc20Contract,
            _amount
        );
    }

    function transferAfterFunding(uint256 _tokenId, address _to)
        external
        nonReentrant
    {
        require(ERC721.ownerOf(_tokenId) == msg.sender);
        require(msg.sender == NFTowner[_tokenId]);
        NFTowner[_tokenId] = _to;
        ERC721.safeTransferFrom(msg.sender, _to, _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
