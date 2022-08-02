import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'
import whitelistMember from '../constant/whitelist.json'

const generateTree = () => {
    const tree = new MerkleTree(whitelistMember, keccak256, {
        hashLeaves: true,
        sortPairs: true,
    })
    return tree
};

export const getTreeRoot = () => {
    const tree = generateTree()
    return tree.getRoot().toString('hex')
}

export const getProofFromHexLeaf = (address) => {
    const hash = keccak256(address)
    const tree = generateTree()
    const proof = tree.getHexProof(hash)
    return proof
};

export const isWhitelisted = (address) => {
    const tree = generateTree()
    const root = getTreeRoot()
    const leaf = keccak256(address)
    const proof = tree.getProof(leaf)
    return tree.verify(proof, leaf, root)
}