import { getProofFromHexLeaf } from "./MerkleTree"
import abi from "../constant/abi.json"
import config from "../constant/config.json"

export const getContract = (web3) => {
    return new web3.eth.Contract(abi, config.CONTRACT_ADDRESS)
}

export const getTotalSupply = async (contract) => {
    return await contract.methods.totalSupply().call()
}

export const balanceOf = async (contract, account) => {
    return await contract.methods.balanceOf(account).call()
}

export const currentState = () => {
    const time = Math.round((new Date()).getTime() / 1000);
    return time < config.PRESALE_TIMESTAMP ? -1 : time < config.PUBSALE_TIMESTAMP ? 0 : 1;
}

export const mint = async (contract, account) => {
    if (currentState() === 0) {
        const proof = getProofFromHexLeaf(account)
        contract.methods.whitelistMint(proof).send({
            from: account,
            value: config.WEI_COST
        })
    } else if (currentState() === 1) {
        contract.methods.mint().send({
            from: account,
            value: config.WEI_COST
        })
    }
}