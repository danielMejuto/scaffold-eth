pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {

  IERC20 token;

  constructor(address token_addr) {
    token = IERC20(token_addr);
  }

  // write your functions here...
  uint256 totalLiquidity;
  mapping(address => uint) public liquidity;

  function init(uint256 tokens) public payable returns (uint256) {
    require(totalLiquidity == 0, "dex already initialized");
    totalLiquidity = address(this).balance;
    liquidity[msg.sender] = totalLiquidity;
    require(token.transferFrom(msg.sender, address(this), tokens));
    return totalLiquidity;
  }

  function price(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public view returns (uint256) {
    uint inputAmountWithFee = inputAmount * 997;
    uint numerator = inputAmountWithFee * outputReserve;
    uint denominator = (inputReserve * 1000) + inputAmountWithFee;
    return numerator / denominator;
  }

  function ethToToken() public payable returns (uint256) {
    uint tokenReserve = token.balanceOf(address(this));
    uint tokensBought = price(msg.value, (address(this).balance - msg.value), tokenReserve);
    require(token.transfer(msg.sender, tokensBought));
    return tokensBought;
  }

  
  function tokenToEth(uint256 tokenAmount) public returns (uint256) {
    uint256 tokenReserve = token.balanceOf(address(this));
    uint256 ethBought = price(tokenAmount, tokenReserve, address(this).balance);
    payable(msg.sender).transfer(ethBought);
    require(token.transferFrom(msg.sender, address(this), ethBought));
    return ethBought;
  }

  function deposit() public payable returns (uint256) {
    uint256 tokenReserve = token.balanceOf(address(this));
    uint256 ethReserve = address(this).balance - msg.value;
    uint256 tokenAmount = ((msg.value * tokenReserve) / ethReserve) + 1;
    uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;
    liquidity[msg.sender] = liquidity[msg.sender] + liquidityMinted;
    totalLiquidity = totalLiquidity + liquidityMinted;
    require(token.transferFrom(msg.sender, address(this), tokenAmount));
    return liquidityMinted;
  }

  function withdraw(uint256 amount) public returns (uint256, uint256) {
    uint256 tokenReserve = token.balanceOf(address(this));
    uint256 ethAmount = amount * address(this).balance / totalLiquidity;
    uint256 tokenAmount = amount * tokenReserve / totalLiquidity;
    liquidity[msg.sender] = liquidity[msg.sender] - ethAmount;
    totalLiquidity = totalLiquidity - ethAmount;
    require(token.transfer(msg.sender, tokenAmount));
    payable(msg.sender).transfer(ethAmount);
    return (ethAmount, tokenAmount);
    
  } 

}