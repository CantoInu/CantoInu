// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

/// @notice Library to encode strings in Base64.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <brecht@loopring.org>.
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Write the length of the string.
                mstore(result, encodedLength)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} iszero(eq(ptr, end)) {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 characters. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                }

                // Offset `ptr` and pad with '='. We can simply write over the end.
                // The `byte(...)` part is equivalent to `[0, 2, 1][dataLength % 3]`.
                mstore(sub(ptr, byte(mod(dataLength, 3), "\x00\x02\x01")), "==")

                // Allocate the memory for the string.
                // Add 31 and mask with `not(0x1f)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(0x1f)))
            }
        }
    }
}

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /*//////////////////////////////////////////////////////////////
                              CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error HexLengthInsufficient();

    /*//////////////////////////////////////////////////////////////
                           DECIMAL OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /*//////////////////////////////////////////////////////////////
                         HEXADECIMAL OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need length * 2 bytes for the digits, 2 bytes for the prefix,
            // and 32 bytes for the length. We add 32 to the total and round down
            // to a multiple of 32. (32 + 2 + 32) = 66.
            str := add(start, and(add(shl(1, length), 66), not(31)))

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 2 + 0x40) is 0x80.
            str := add(start, 0x80)

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(bytes memory value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 2 + 0x40) is 0x80.
            str := add(start, 0x80)

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 40 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 40) is 96.
            str := add(start, 96)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        uint256 i = 2 * length;
        while (i > 0) {
            --i;
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    
}

//this contract has one purpose, to build the defs
contract DEFS {

    // common assets - used in all IDs | we also include word bubble style even if it isn't used for all
    string constant STYLE_STATS = '<style>.stats{fill:#fff;font:14px courier}</style><style>.words{font:14px Tahoma;font-style:oblique}</style>';
    // @TODO move dogPath into PNG
    string constant G_CINU_PNG = '<path id="dogPath" d="M 22.3,2.5 H 328 c 11,0 19.8,8.8 19.8,19.8 V 328 c 0,11 -8.8,19.8 -19.8,19.8 H 22.3 c -11,0 -19.8,-8.8 -19.8,-19.8 V 22.3 c 0,-11 8.8,-19.8 19.8,-19.8 z" /><g id="cINU"><image transform="scale(0.25)" href="data:image/png;base64,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"/></g>';
    string constant FILTER_TV_NOISE = '<filter id="tvnoisefilter"><feTurbulence type="fractalNoise" result="static1" baseFrequency="0.1" numOctaves="1" seed="0"><animate attributeName="baseFrequency" values="0 0.65;0 0.8;0 0.65;0 0.80.65;0 0.8" dur="2.5s" repeatCount="indefinite" /></feTurbulence><feTurbulence type="fractalNoise" result="static2" baseFrequency="0.1" numOctaves="5" seed="2"><animate attributeName="baseFrequency" values="0.9 0.5;0.8 0.8;0.9 0.9;" dur="0.2s" repeatCount="indefinite" /></feTurbulence><feComposite operator="lighter" in="static1" in2="static2" result="blackcomposite"/><feColorMatrix in="blackcomposite" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0" /></filter>';
    
    //move this
    string constant G_BACKGROUND_0 = '<rect width="350" height="350" rx="20" fill="';
    //WhiteSmoke
    string constant G_BACKGROUND_1 = '" stroke-width="0.1" stroke="black"/><g mask="url(#screen)"><rect width="310" height="310" x="20" y="20" rx="20" fill="';
    //white
    string constant G_BACKGROUND_2 = '"/><rect width="310" height="310" x="20" y="20" rx="20" filter="url(#tvnoisefilter)"/></g>';

    //feature specific assets - applied depending on the attr
    string constant ATTR_NO_SECOND_BEST = '<filter id="blur" y="-100%" height="200%"><feGaussianBlur in="SourceGraphic" stdDeviation="4"/></filter><radialGradient id="glow"><stop offset="0%" stop-color="orange"/><stop offset="100%" stop-color="yellow"/></radialGradient><g id="noSecondBest"><path id="star" d="M570.33 225L416.45 229.41L547.51 310.16L412.04 237.04L485.16 372.51L404.41 241.45L400 395.33L395.59 241.45L314.84 372.51L387.96 237.04L252.49 310.16L383.55 229.41L229.67 225L383.55 220.59L252.49 139.84L387.96 212.96L314.84 77.49L395.59 208.55L400 54.67L404.41 208.55L485.16 77.49L412.04 212.96L547.51 139.84L416.45 220.59L570.33 225Z" transform="translate(-140, 23) scale(0.3 0.1)" filter="url(#blur)" style="transform-origin:center center;fill:gold;mix-blend-mode:screen"/><ellipse cx="108" cy="203" rx="5" ry="3" filter="url(#blur)" style="fill:url(&quot;#glow&quot;);mix-blend-mode:screen"/><ellipse cx="108" cy="203" rx="5" ry="3" opacity="0.1" filter="url(#blur)" style="fill:#fff;mix-blend-mode:screen"/><path id="beam1" d="M553 225L400 230L297 225L400 220L203 225Z" transform="translate(-290, 20) scale(1, 0.2)" filter="url(#blur)" style="transform-origin:center center;fill:gold;mix-blend-mode:screen"/><path id="beam1" d="M553 225L400 230L297 225L400 220L203 225Z" transform="translate(-270, 15) scale(1, 0.2)" filter="url(#blur)" style="transform-origin:center center;fill:gold;mix-blend-mode:screen"/></g>';
    string constant ATTR_DEAL_WITH_IT = '<g id="dealWithIt"><path d="m132 198v1.65h-9.91v1.65h-1.65v1.65h-1.65v1.65h-1.65v1.65h-9.91v-1.65h-1.65v-1.65h-1.65v-1.65h-3.3v1.65h-1.65v1.65h-11.6v-1.65h-1.65v-1.65h-1.65v-3.3h46.2zm0 1.65h3.3v1.65h-3.3z"/><path d="m119 200v1.65h-1.65v-1.65zm-1.65 1.65v1.65h-1.65v-1.65zm-1.65 0h-1.65v-1.65h1.65zm-1.65 0v1.65h-1.65v-1.65zm-1.65 1.65v1.65h-1.65v-1.65zm1.65 0h1.65v1.65h-1.65z" fill="#fff"/><path d="m99 200h-1.65v1.65h-1.65v-1.65h-1.65v1.65h-1.65v1.65h1.65v-1.65h1.65v1.65h1.65v-1.65h1.65z" fill="#fff"/></g>';
    string constant ATTR_NOUNDER = '<g id="nounder"><rect x="88" y="198" width="47" height="2.5" fill="red"/><rect x="135" y="198" width="2.5" height="7.5" fill="red"/><rect x="87.5" y="195" width="15" height="15" fill="red"/><rect x="105" y="195" width="15" height="15" fill="red"/><rect x="90" y="197.5" width="5" height="10" fill="white"/><rect x="95" y="197.5" width="5" height="10" fill="black"/><rect x="107.5" y="197.5" width="5" height="10" fill="white"/><rect x="112.5" y="197.5" width="5" height="10" fill="black"/></g>';
    string constant ATTR_MILADY = '<g id="milady"><ellipse cx="108" cy="201" rx="3.1" ry="4.9" fill="#483D8B"/><ellipse transform="rotate(-8)" cx="68" cy="211" rx="2.2" ry="5" fill="#483D8B"/><path d="m97 188c1.2 0.85-0.36 1.8-0.88 2.2-0.93 0.91-2.1 1.5-2.5 3.2-0.11 0.96-0.85 0.61-0.55-0.29 0.23-1.6 0.94-2.9 1.9-3.6 0.67-0.54 1.3-1.5 2.1-1.6z"/><path d="m106 189c1.3 0.24 2.6 0.62 3.6 1.8 0.74 0.88 1.5 1.8 2.2 2.7 0.39 0.39 1.2 2.5 0.27 1.7-0.8-1.2-1.8-2.2-2.6-3.3-1.1-1.2-2.5-1.1-3.8-1.6-0.68-0.48-0.27-1.6 0.35-1.4z"/><path d="m96 193c0.69 0.04 1.4 0.68 1.9 1.4-0.16 0.88-1-0.77-1.5-0.54-0.82-0.16-1.6 0.24-2.3 0.54 0.022-1.2 1.1-1.3 1.8-1.4l0.11-8e-3z"/><path d="m96 195c0.35 1.1-0.57 3.4 0.74 3.3 0.58-0.8 0.11-2-0.46-2.6-0.31-1.5 1-0.15 1.3 0.47 0.57 0.81 1.2 2.3 0.94 3.3-0.52 0.38-0.64-1.5-0.66-0.28-0.01 1.4-0.053 3-0.77 3.9-0.63 0.41-1.4-0.5-1.7-1.4-0.55-1.6-0.84-3.2-1.1-4.9-0.49 0.79 0.62 2.8-0.11 2.9-0.1-0.56-0.32-1.7-0.44-0.53-0.67 0.3-0.1-1.7-0.037-2.3 0.13-1.1 0.83-1.8 1.6-1.8 0.21-0.026 0.42-0.036 0.62-0.058z"/><path d="m107 195c1.1 0.2 2.4 0.37 3.3 1.7-0.26 0.96-1.2-0.71-1.8-0.63-0.89-0.32-1.8-0.44-2.7-0.096-0.69 0.4-0.72-0.92-0.067-0.79 0.39-0.13 0.8-0.13 1.2-0.15z"/><path d="m108 196c0.48 0.085 1.7 0.21 1.5 1.1-0.68-0.65-1.5 0.24-1 1.4 0.77 0.92 1.2-0.81 1.6-1.4 0.87 0.74 1.9 1.6 2.1 3.2 0.12 0.48 0.61 2.3-0.028 1.6-0.22-1.3-1.1-2.6-1.8-2.9-0.22 1.4-0.38 3-1 4.1-0.61 1-1.8 0.94-2.5-0.2-0.49-0.62-0.67-1.9-1-2.4-0.12 0.62 0.13 1.8-0.62 1.4-0.09-1.1-0.11-2.3 0.13-3.4 0.4-1.6 1.4-2.6 2.6-2.5z"/><path d="m65 200c0.26 1.4 0.66 2.7 1.3 3.8-0.54 0.63-0.98-1.4-1.2-2.1-0.056-0.49-0.67-2-0.048-1.7z"/><path d="m99 200c0.088 1.5 0.2 3.2-0.6 4.2-0.67 0.94-1.6 1.8-2.6 1.6-0.63-0.43 0.017-0.89 0.4-0.71-0.16-1.1 0.61 0.17 0.92-0.52 0.64-0.45 1.5-1 1.4-2.3 0.19-0.83-0.65-2.8 0.42-2.3z"/><path d="m111 200c0.92 0.59 0.39 2.2 0.28 3.2-0.26 1.3-0.96 2.2-1.7 2.9 0.085 0.25 1.1-0.04 0.61 0.78-0.56 0.85-1.5-0.065-2.2-0.15-0.58 0.025-0.76-0.79-0.18-0.96 0.73 0.73 1.4-0.16 1.9-0.73 0.95-1.1 1.2-3 1.2-4.8l-7e-5 -0.18z"/><path d="m106 202c0.16 1.1 0.74 2 1.4 2.5-0.45 1.6-1.4-0.42-1.7-1.3-0.34-0.75-0.39-1.8 0.29-1.2z"/></g>';
    string constant ATTR_AMPLICE = '<filter id="pixelate"><feFlood height=".5" width=".5"/><feComposite width="2" height="2"/><feTile result="a"/><feComposite in="SourceGraphic" in2="a" operator="in"/><feMorphology operator="dilate" radius="1"/></filter><filter id="black-glow"><fecolormatrix type="matrix" values="0.2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0"/><feGaussianBlur stdDeviation="2.5" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter><g id="amplice" transform="rotate(-10 640 0) translate(-0 0) skewX(40) scale(1 0.5)" filter="url(#pixelate)"><ellipse cx="11" cy="176" rx="20" ry="10" fill="none" stroke="red" stroke-width="2" filter="url(#black-glow)"/></g>';

    string constant USE_1 = '<use xlink:href="#';
    string constant USE_2 = '"/>';

    function setEyes(uint8 _eyeAttr) internal pure returns (string memory SELECTED_EYE_ATTR) {

        //only assign attributes to half of dogs
        if (_eyeAttr != 255) {
            if(_eyeAttr == 0) {
                SELECTED_EYE_ATTR = ATTR_NO_SECOND_BEST;
            } else if(_eyeAttr == 1) {
                SELECTED_EYE_ATTR = ATTR_DEAL_WITH_IT;
            } else if(_eyeAttr == 2) {
                SELECTED_EYE_ATTR = ATTR_NOUNDER;
            } else {
                SELECTED_EYE_ATTR = ATTR_MILADY;
            } 
        }
    }

    function getAttrName(uint8 _eyeAttr) internal pure returns (string memory) {
        if(_eyeAttr == 0) {
            return 'noSecondBest';
        } else if(_eyeAttr == 1) {
            return 'dealWithIt';
        } else if(_eyeAttr == 2) {
            return 'nounder';
        } else {
            return 'milady';
        } 
    }

    function getAttributePlacements(uint8 eyeAttr, bool amplice) public pure returns (string memory useStr) {

        if(eyeAttr != 255) {
            useStr = string.concat(
                USE_1,
                getAttrName(eyeAttr),
                USE_2
            );
        }

        if(amplice) {
            useStr = string.concat(
                USE_1,
                'amplice',
                USE_2
            );
        }
        
    }
        
    // starting with common base def assets
    function buildDefs(uint8 eyeAttr, bool amplice) public pure returns (string memory) {

        return string.concat(
            '<defs>',
            STYLE_STATS,
            FILTER_TV_NOISE,
            G_CINU_PNG,
            setEyes(eyeAttr),
            amplice ? ATTR_AMPLICE : "",
            '</defs>'
        );
    }

    function getBackground(string memory _borderLvlColor, string memory _noiseColor) public pure returns (string memory) {
               
        return string.concat(
            G_BACKGROUND_0,
            _borderLvlColor,
            G_BACKGROUND_1,
            _noiseColor,
            G_BACKGROUND_2
        );
    }

    function createPNGs(uint256 count) public pure returns (string memory pngRunners) {
        
        pngRunners = '<use xlink:href="#cINU"><animateMotion dur="40s" repeatCount="indefinite" rotate="auto"><mpath xlink:href="#dogPath"/></animateMotion></use>';

        if(count > 1) {
            unchecked {
                for (uint256 i = 1; i<count; i++) {
                    pngRunners = string.concat(
                        pngRunners, 
                        '<use xlink:href="#cINU"><animateMotion dur="40s" begin="-',
                        LibString.toString(i * (40/count)),
                        's" repeatCount="indefinite" rotate="auto"><mpath xlink:href="#dogPath"/></animateMotion></use>'
                    );
                }   
            }
        }

    }

}

//this contract has one purpose, to deliver the doge
contract DOG{

    string constant LAYER_0 = 'm113 189c-4.74 4.7-14.9 6.06-15.4 13.7 0.8 4.46-3.27 12.5 3.46 11.65 1.09 3.93 0.49 7.08 5.61 7.6 5.6 2.51 3.62 9.63 5.66 14.39 1.42 7.43 4.21 14.65 9.15 20.45 4.44 8.72 3.62 18.88 5.54 28.27 2.44 6.51-6.59 8.67-8.34 12.79-0.36 2.73 3.05 0.81 5.13 3 7.4 4.38 15.63-2.61 13.32-10.46-0.44-8.86 0.74-17.6 2.7-26.2 1.62-6.63 0.18-16.15 9.5-15.5 16.3-3.9 32.6-7.79 48.9-11.69 2.59 8.42 1.35 18.47 7.89 25.29 5.56 6.16 11.46 10.1 11.95 18.92 2.5 6.04-0.53 13.51-4.71 16.7 4.68 4.74 13 0.77 11.2-6.14-0.65-3.58 3.36-8.33 3.86-2.18 1.71 4.94-7.3 17.68 2.24 15.54 6.82-5.13 2.9-11.32 3.22-18.18-2.08-8.4-8.94-20.9-12.24-28.86-6.17-13.42-13.36-26.4-20.75-39.14-6.8-5.19-16.19-1.23-24.07-2.91-12.69-0.59-25.38-1.3-38.04-2.45-5.68-3.63-8.8-9.9-13.6-14.5-3.27-4.3-7.1-7.98-12.18-10z';
    string constant LAYER_1 = 'm228 304c-0.76-5.19 9.68-0.88 3.18-0.17-1 0.17-2.17 0.68-3.18 0.17zm-1.39-0.6c-2.19-4.69 5.22-10.94 0.02-14.57-0.14 2.73-2.61 11.68-4.48 9.29 3.25-3.61 3.13-12.75-2.73-12.2-0.4 7.39-1.14-5.04-2.15-7.08-5.72-7.69-14.32-13.94-16.84-23.69-3.46-7.66-13.63-8.52-20.6-5.69-8.37 2.37-16.54 5.43-24.38 9.2-8.58-0.54-14.51 6.49-13.18 14.77-3.54 7.96-0.84 16.75-5.09 24.22-0.54 7.14-17.02 7.81-12.82 0.51 2.92-2.05-3.02 4.65 2.57 3.65 3.87 1.31 11.74-2.12 8.73-7.16-1.4 3.9-6.23-3.35-5.96 1.93-5.3 2.14 4.4-8.51 2-12.13-0.65-7.35 1.41-15.63-3.41-21.99-6.72-2.13-2.42 9.61-1.89 13.35-0.14 4.16 6.64 12.52 0.38 14.47-0.57-8.28-2.44-18.23-2.56-26.53-1.73-8.63-10.35-13.83-11.72-22.63-2.58-6.15-5.73-11.72-8.33-17.49-4.31-2.88-8.42-2.48-9.18-8.89-1.99-5.64 2.48-9.79 0.84-15.59 2.75-5.41-3.62-13.03 0.75-16.78 5.71 0.89 10.67 7.97 16.77 3.41 3.49-3.16 6.41-4.57 9.05 0.45 5.22 5.81 8.98 12.8 14.46 18.35 6.18 6.23 16.36-0.76 22.39 5.66 7.42 2.56 15.44 0.63 23-0.17 8.19-0.17 2.69-8.28 6.25-12.55 4.29-7.76 16.11-12.7 23.41-6.05 5.51 5.21 7.98 13.3 7.61 20.71-2.81 6.81 1.63 12.03 4.93 17.43 3.36 6.72 3.09 14.42 1.97 21.63-0.29 8.53-0.64 18.1 5.1 24.96 2.96 6.13 2.05 13.12 3.21 19.65 0.94 4.24-3.17 7.19-3.44 1.34-2.14-3.76-6.1 4.96-4.71 6.21zm4.84-7.85c-0.57-0.87-0.14 1.18 0 0zm-1.58-2.16c-0.68-0.5-0.29 0.92 0 0zm-2.93-9.8c-0.43-0.77-0.29 0.68 0 0zm-0.71-1.02c-8e-3 -4.52-4.37-1 0 0zm-16.09-18.95c-0.23-0.62-0.32 0.66 0 0zm-0.56-1.62c-1.05-3.53-2.82-0.08 0 0zm-2.06-2.46c0.09-1.86-2.28-0.14 0 0zm-1.11-2.4c-1.74-4.29-2.64 1.11 0 0zm-77.27-2.2c2.67-5.76 6.86-17.07-3.37-17.27-2.13-1.34 2.44-7.47 1.56-9.14-3.08 1.2-9.87 7.94-10.23 2.79-3.96-0.67-5.88 2.73-3.1 4.04 2.34-0.63 7.82 5.88 1.8 2.91-2.85-1.28-0.25 11.57 1.42 6.74-1.15-4.28 3.83-3.65 2.44 0.31 1.65 3.93 9.96 6.76 9.48 9.62zm-0.72-2.23c0.45-2.13 1.36 1.12 0 0zm-7.32-11.28c0.51-2.2 1.04 1.93 0 0zm-5.51-0.12c0.76-3.58 3.66 1.51 0 0zm8.88-0.67c-5.76-2.35-2.31-4.63 0.23-0.8zm-1.27-4.21c-0.84-2.67 1.16 1.48 0 0zm-2.93-1.02c0.15-1.52 1.42 1.16 0 0zm-1.98-0.61c0.66-2.19 1.65 0.69 0 0zm3.59-2.04c-0.41-0.86 0.98 0.22 0 0zm81.66 22.1c-0.61-1.18-0.82 1.31 0 0zm-81.56-5.77c-0.64-0.51-0.34 0.38 0 0zm-3.05-4.16c-1.03-1.59-0.5980.784 0 0zm-4.45-5.23c1.37-4.42-3.04 1.51 0 0zm-0.62-4.31c-0.64-0.34-0.05 0.82 0 0zm4.77-7.51c-0.81-0.97-0.64 1.38 0 0z-53-3.9c0.47-2.22-3.23-2.98 1.14-4.05z4.26-2.94 10.13-7.79 8.2-11.92 0.88-4.53-10.52-6.69-11.97-1.34-7.23-4.12-4.78 10.82 1.59 4.47 3.7-0.44 3.39 2.04 1.37 3.26 0.74 2.77-6.99 10.41-0.33 9.57zm4.59-12.3c0.68-2.36 3.25 0.85 0 0zm-4.83 10.25c-0.23-0.62-0.32 0.66 0 0zm-15.09-5.52c-0.58-0.93-0.49 0.93 0 0zm5.03-2.57c2.2-3.97-6-2.95-0.44-0.44l0.26 0.27zm-0.18-0.82c0.13-1.26 1.15 0.88 0 0zm0.18-2.82c-0.49-0.74-0.41 0.7 0 0zm8.13-6.63c-0.57-0.81-0.42 0.99 0 0zm-9.47-0.45c-0.89-0.93-0.19 1.59 0 0zm116.53 96.76c-1.38-1.45 3.94 0.79 0 0zm-4.48-0.35c-7.1-2.27 9.12-8.07 1.69-3.09-5.25 2.39 6.09 1.58-0.38 3.51-0.33-0.12-0.99-0.3-1.32-0.43zm-93.71-1.23c0.82-2.04 2.69 1.18 0 0zm3.61-0.15c0.6-0.81 0.47 0.74 0 0zm8.6-0.97c-1.65-1.75 1.67 0.17 0 0zm-8.3-2.71c0.9-3.4 3.79-5.1 1.43-0.68-0.26 0.49-0.85 0.89-1.43 0.68z';
    string constant LAYER_2 = 'm229 304c1.23-3.12 4 1.48 0 0zm-102.85-1.29c1.38-1.97 3.33 0.04 0 0zm-1.14-0.38c0.23-0.62 0.32 0.66 0 0zm4.45 3e-3c1.76-1.67 1.09 0.79 0 0zm-6.8-1.66c2-2.76 1.47-0.06 0 0zm92.26-1.16c0.52-2.63 2.53 1.45 0 0zm6.63-0.18c0.79-2.03 2.09 0.84 0 0zm-100.62-1.23c0.64-0.51-1.08-0.39 0 0zm90.86-0.09c1.35-3.09 4.59-1.96 0 0zm21.86-0.39c-2.31-7.67-5.41-15.13-6.9-23.04-3.31-5.15-13.46-1.05-13.61-9.69-1.95-7.13-10.27-10.03-13.24-15.65 6 0.81-3.82-4.5-4.11 0.1-6.4-2.65-12.6-2.2-18.91 0.73-6.63 1.32-12.9 3.71-18.61 7.3-2.9 1.9-7.63 0.27-2.43-1.6 4.27-0.63 9.07-5.69 6.35-8.94-2.75 0.36-3.97 2.66-3.99-0.09-3.73-1.64-4.3 1.63-3.85 2.93-4.18-0.11-12.05 6.95-5.64 8.68 9.73-2.58-8.58 7.36-4.04 0-2.99-3.86-5.05 6.94-8.65 7.97-1.17 3.23-4.39 7.16-3.88 1.29-0.33-5.75-0.94-11.03 1.93-15.98 0.1-5.95 1.12-12.35-0.97-18.02-2.24-2.79-6.99 2.82-3.49-2.13 2.95-3.22 3.74-12.69-2.68-7.34-2.42 1.32-13.31 2.2-6.73 5.45-2.46 3.11-10.92-0.13-9.23 6.11-5.8-3.71-2.34-15.11-11.97-14.48-4.58-1.83 6.46-3.26 0.86-3.19-6.07 2.74-7.46-10.76-4.21-9 6.2-1.19 1.68 9.59 8.3 6.49 2.92-1.95 9.55-4.37 5.79 1.22 6.84-2.54-5.71 9.3 2.14 9.59 7.72 0.11 5.84-8.65 10.71-12 5.68-5.68 3.5-17.3-3.67-20.4-1.75 3.03 6.75 8.86-0.03 5.6-5.25 4.8-9.7-5.19-14.66-0.59-5.52 2.47-4.45-3.98-3.5-6.81-3.42-2.98-7.56-2.33-5.49-8.62 3.56-3.95 8.66 5.82 14.06 4.02 5.11 0.64 8.1-9.9 12.18-2.07 4.92 6.49 9.48 13.31 14.9 19.39 6.35 6.05 16.48-0.56 22.69 5.66 7 3.04 14.6-0.17 21.87 0.29 9.02 0.04 4.41-9.4 8.28-13.92 2-3.21 4.5 7.41 5.1 1.69 2.09 3.88 2.98 0.89 3.24 1.32 0.99-3.59 1.6 0.42 2.93-1.59 2.43 1.49 3.5-0.26 4.13 2.15 2.67-1.54 2.21 1.29 3.69-0.65 3.69 0.73 3.54 7.89 7.15 2.92 4.45 0.2 3.48 11.15 2.94 17.27 0.07 3.28-0.02 6.44 1.18 8.12-4.13 1.64-2.17 10.16-4.25 10.88 5.76 1.85-0.13 2.04-2.38 2.14 3.98 0.56 5.92 3.22 5.75 6.4 1.26 1.72 6.04 4.67 6.06 0.56 2.91 6.17-0.69 13.35 2 19.75-0.46 4.88 2.54 9.32 5.49 11.66 0.3 6.04 2.44 12.02 1.38 18.1zm0.44-1.51c-0.38 0.34 0.51 0.64 0 0zm-6.45-21.75c-0.22-0.65-0.49 0.4 0 0zm-14.5-11.66c-0.23-0.62-0.32 0.66 0 0zm2.52-3.45c2.47-0.44-1.38-0.32 0 0zm-3.57-1.34c-1.65-1.26 0.47 1.59 0 0zm3.19-0.13c-1.24-1 0.14 0.68 0 0zm1.9-0.16c-0.32-0.66-0.23 0.62 0 0zm-2.85-0.16c-0.36-0.67-0.36 0.68 0 0zm-0.91-0.91c-0.84-4.08-2.98 1.08 0 0zm-2.42-0.09c-0.77-3.03-2.99-0.03 0 0zm3.65-0.19c-0.42-0.92-0.39 0.92 0 0zm1.52-0.15c-0.87-3.47-4.52 0.54 0 0zm5.04-2.15c-0.77-1.33-2.6 1.23 0 0zm-5.33-0.34c-0.42-0.99-0.58 0.81 0 0zm6.21-0.86c1.77-1.56-2.3 0.73-0.17 0.03zm-57.92-0.62c-2.24-1.85 0.9 1.88 0 0zm60.57-0-0.33 0.04zm-9.12-0.75c-1.68-2.56-3.62-0.04 0 0zm-11.12-0.18c-0.59-0.64-0.35 0.94 0 0zm-0.8-0.33c-0.72-0.86-0.27 1.27 0 0zm-38.83-0.69c-0.71-1.72-1.29 0.45 0 0zm43.11-1.09c-0.13-0.93-0.65 0.57 0 0zm-4.66-1.23c-1.4-0.05 0.5 2.54 0 0zm-7.46 0.55c1.21-2.65 9.76-2.34 5.52-6.6-4.81-2.42-4.49 2.84-7.86 3.97-0.26 1.35 1.51 2.02 2.34 2.62zm0.99-2.79c0.75-0.52 0.13 0.42 0 0zm2.6-1.18c0.62-1.36 0.71 0.75 0 0zm-0.65-0.98c-0.85-1.54 3.13 1.24 0 0zm13.8 4.62c-1.22-0.5 0.53 1.08 0 0zm1.67-0.41c-1.19-2.22-2.13 1.85 0 0zm-12.58-0.21c3.43-1.04-1.79-0.63 0 0zm-50.31-0.14c-0.41-1.11-0.79 0.75 0 0zm12.84 5e-3c-0.36-0.67-0.36 0.68 0 0zm-13.79-0.45c-1.02-1.7-1.42 0.43 0 0zm2.02-0.14c-1.32-2.06-2.76 0.49 0 0zm50.6-0.05c-0.32-0.66-0.23 0.62 0 0zm-11.08-0.89c4.15-2.5-3.42-1.87 0 0zm0.02-1.04c0.42-0.99 0.58 0.81 0 0zm-38.47 0.82c5.18 0.04-3.12-2.05 0 0zm0.4-0.57c0.57-0.52 0.3 1.08 0 0zm-3.96 0.59c-0.46-1.43-0.72 0.69 0 0zm0.36-0.51c-1.39-1.04 0.07 0.93 0 0zm39.56-0.52c0.38-3.37-2.8 1.4 0 0zm22.2 0.23c-0.71-1.76-1.21 1.17 0 0zm-60.23-0.33c2.56-2.32 11.32-0.82 3.66-3.43-3.97-1.46-1.42 0.26-4.9 0.86-1.56 1.02-0.55 3 1.23 2.57zm4.05-2.3c-0.44-1.06 1.85 1.45 0 0zm18.86 1.36c-1.31-4.72-2.99 1.78 0 0zm20.06 0.45c1.17-1.78-2.21 1.43 0 0zm-12.14-0.14c-0.23-0.62-0.32 0.66 0 0zm3.04-0.57c3.38 2.8 6.08-6.17 2.08-1.26-0.78 0.3-5.16 1.04-2.08 1.26zm-26.81 0.25c-0.68-0.82-0.58 0.77 0 0zm55.54-0.22c0.54-1.86-2.17 2.03 0 0zm1.6-0.1c0.27-1.17-1.15 1.58 0 0zm-40.61-0.17c-0.47-0.76-0.47 0.76 0 0zm18.34-0.15c-0.84-0.8-0.94 0.85 0 0zm19.26 0c-0.36-0.67-0.36 0.68 0 0zm-22.19-0.16c-0.41-0.7-0.49 0.74 0 0zm1.58 0c-0.54-0.75-0.54 0.75 0 0zm18.2-0.41c1.02-1.68-3.27 1.25 0 0zm-52.04-1.18c-2.46-1.75-1.36 0.7 0 0zm3.03-0.6c-2.88-0.55 0.17 1.23 0 0zm35.72 0.35c3.74-2.54-6.4 0.72 0 0zm-38.41-0.2c1.69-3.2-2.44-0.9 0 0zm33.42-0.19c-0.23-0.62-0.32 0.66 0 0zm21.12-0.29c0.85-1.85-3.98 1.96 0 0zm4.32 0.16c-2.1-1.44-1.02 0.73 0 0zm-54.56-0.32c-0.8-0.86-0.63 1.32 0 0zm23.58-0.04c0.07-0.89-0.68 0.83 0 0zm-32.26-0.47c3.65-0.44-2.11-2.73 0 0zm55.08-0.31c-0.33-1.52-0.87 0.9 0 0zm2.46-0.16c-0.53-1.26-0.43 1.14 0 0zm-16.88 0c-0.58-0.77-0.68 0.82 0 0zm-27.21-0.66c3.77-0.4 1.38-0.86-0.83-0.07zm-12.12-0.83c-0.04-2.22-1.43 0.64 0 0zm39.65-0.08c-0.61-1.13-0.68 1.21 0 0zm-38.91 0.09c-0.45-0.66-0.6 0.44 0 0zm42.47-4.05c1.2-3.56-2.95 1.23 0 0zm2.7-0.64c0.08-1.19-2.44 1.22 0 0zm-69.61-1.11c-0.65-0.64-0.25 1.03 0 0zm68.03-0.19c-1-0.94-0.48 1.58 0 0zm-66.89 0.19c-0.5-1.2-1.14 0.86 0 0zm70.06-0.48c-0.41-0.7-0.49 0.74 0 0zm-1.43-0.65c-0.72-0.41-0.35 0.88 0 0zm-3.99-0.2c-0.24-1.44-1.1 1.22 0 0zm-85.08-2.64c1.47-3.16-2.27 2.89 0 0zm20.33-5.8c3.74-2.34-0.3-2.43-1-0.03zm13.43-0.85c-0.54-0.75-0.54 0.75 0 0zm-44.06-0.16c-0.36-0.67-0.36 0.68 0 0zm1.33-0.17c4.92-2-2.1-1.14 0 0zm44.98-0.76c0.44-2.19-1.75 1.83 0 0zm-27.77-1.13c-0.87-0.87-0.73 0.81 0 0zm27.64-0.1c-0.29-0.6-0.48 1.26 0 0zm-13.93-0.15c7.25-0.94-2.25-0.79 0 0zm13.3-0.24c3.65-7.34-4.12 1.17 0 0zm-11.56-1.34c1.15-1.38-2.17 0.73 0 0zm-38.52-0.44c0.61-2.08-1.91 0.78 0 0zm36.97-1.33c-0.46-0.75-0.32 1.03 0 0zm1.85 0.1c3.37-0.71-1.88-3.5 0 0zm11.25-0.4c-0.13-1.69-0.87 1.6 0 0zm-0.14-1.17c2.73-5.12-5.54-0.57 0 0zm-9.44-0.94c-0.23-0.62-0.32 0.66 0 0zm0.3-2.93c-2.35-1.46-2.23 5.34-0.41 0.76zm1.29-1.35c-1.11-0.46-0.57 1.44 0 0zm-1.24-1.07c1.51-2.2-2 0.3 0 0zm75.3-0.57c5.28-5.1-2.91-1.25 0 0zm2.87-0.06c2.73-3.37-2.03 0.37 0 0zm-23.52-3.52c-0.17-0.9-0.54 0.63 0 0zm2.42-0.58c0.14-1.86-1.38 0.51 0 0zm-3.22-0.85c-0.54-0.75-0.54 0.75 0 0zm5.57-0.58c-1.07-2.44-0.05 1.65 0 0zm-81.21-2.74c3.14-4.04-3.79 0.17 0 0zm1.31 0.15c-0.43-0.83-0.46 0.49 0 0zm71.96-0.09c8e-3 -2.05-1.19 0.42 0 0zm-74.04-1.26c-1.3-3-2.1 1.59 0 0zm-2.48-0.16c-0.31-1.43-0.72 1.65 0 0zm2.4-1.8c-0.18-1.19-0.8 1.03 0 0zm-0.7-0.72c-0.66-1.86-1.16 1.23 0 0zm2.5-0.71c-1.2-3.69-4.38 0.8 0 0zm5.37-0.46c2.23-3.58-1.91 0.89 0 0zm-23.04-3.42c1.32-3.43-3.86 0.04 0 0zm-4.21-3.7c-0.67-1.63-0.73 1.13 0 0zm2.42-0.83c-1.58-2.51-1.69 0.4 0 0zm124.9 111.83c7e-3 -3.52 1.29 0.59 0 0zm-94.92-2.26c-1.97-3.76 1.86 1.04 0 0zm96.14-3.59c1.32-4.26-8.32-9.66-6.14-2.68 1.37-8.85-5.49-15.39-10.98-21.17-3.29-4.04-6.88-8.43-7.34-13.83 6.48 5.52 10.7 13.14 16.86 18.99 3.86 4.57 12.35 12.75 7.6 18.69zm-98.42-5.12c-0.59-4.34 1.08-4.45 0 0zm-0.9-8.51c-1.3-2.83-0.43-9.87-0.07-2.87-0.1 0.82 0.9 2.21 0.07 2.87zm97.69-4.88c-8e-3 -1.25 0.73 1.02 0 0zm-2.06-0.48c0.24-1.25 0.87 1.21 0 0zm-91.26-7.8c-2.73-6.91-11.14-9.1-14.36-15.76 2.32-2.08 9.98 4.56 12.19 8 0.83 1.47 4 7.87 2.17 7.76zm67.35-14.05c-0.56-3.48 3.03-0.59 0 0zm-39.87-0.74c-1.36-1.03 3.71 1.45 0 0zm1.43-0.38c0.41-0.7 0.49 0.74 0 0zm67.09-2.96c-0.59-1.11 1.29 0.31 0 0zm-6.14-0.53c0.6-0.82 0.65 0.64 0 0zm6.49-0.49c-0.32-1.24 0.74 0.39 0 0zm-7.36-3.16c0.32-0.66 0.23 0.62 0 0zm-1.14-5.97c0.75-0.52 0.13 0.42 0 0zm-94.2-9.88c0.43-0.77 0.29 0.68 0 0zm95.81-0.55c0.17-0.9 0.54 0.63 0 0zm-101.82-3.24c-0.43-0.94 0.61 0.22 0 0zm-18.9-14.7c1.81-4.66 11.77-9.18 13.29-5.65-4.13 2.55-8.95 3.56-13.29 5.65zm-1.72-3.55c-0.25-2.28 0.95 1.58 0 0zm1.19-0.51c-5.43-1.48-0.78-16.92 0.95-9.03-1.52 3.12-2 5.7-0.37 8.81zm115.24 0.12c-0.16-1.95 1.06 0.54 0 0zm-90.16-1.46c0.8-1.45 0.66 1.05 0 0zm93.84-0.87c0.63-0.92 0.63 0.92 0 0zm-94.19-0.09c-2.4-1 2.61-0.04 0 0zm-3.53-0.99c-0.71-1.72 1.4 0.86 0 0zm76.62-1.31c-1.03-1.55 1.11 0.3 0 0zm19.85-1.13c-0.29-1.47 1 0.73 0 0zm-21.68-0.22c-0.43-0.94 0.61 0.22 0 0zm1.19-0.11c0.18-0.58 0.08 0.81 0 0zm-3.76-2.38c-1.89-2.94 1.61 0.95 0 0zm1.58-1.02c-2.09-3.69 5.83-2.74 0.5-0.34l-0.31 0.21zm15.65-3.67c-1.99-1.59 0.99-1.47 0 0zm-6.95-1.55c-0.25-2.48 1.27 1.13 0 0zm-3.75 0.51c0.93-1.56 0.96 0.84 0 0zm1.97-0.76c-0.08-1.03 1.08 1.24 0 0zm5.15-0.08c-0.02-1.29 0.97 0.75 0 0zm-0.94-0.14c0.23-0.62 0.32 0.66 0 0z';
    string constant LAYER_3 = 'm229 303c0.37-0.91 0.37 0.91 0 0zm-14.17-3.84c9e-3 -1.16 1.31 0.63 0 0zm-2.95-2.04c1.13-2.18 1.45 0.28 0 0zm12.77-5.79c-4.6-7.06-9.34-14.17-14.65-20.64-3.64-3.87-10.2-11.92-9.19-15.17 6.38 4.86 9.96 12.51 16.02 17.8 3.89 4.72 11.52 11.33 7.82 18zm-6.32-2.37c-0.95-3.87 0.58-5 0 0zm-93.5-12.59c-1.34-2.55 0.86-1.43 0 0zm100.03-11.64c-2.02-1.19 1.8 0.6 0 0zm-95.51-0.99c-1.61-5.69-13.59-10.55-12.4-13.65 4.81 2.45 8.84 2.91 10.98 9.05 0.7 1.45 1.27 2.99 1.42 4.61zm-11.94-13.75c-1.07-1.17-1.02 0.86 0 0zm106.42 12.11c-0.42-0.9 1.23 0.97 0 0zm-78.84-2.03c1.91-2.78 0.13 1.97 0 0zm79.49 0.1c-3.38-2.43 4.29-0.43 0 0zm-89.42-0.87c1.45-2.84 10.16-7.52 5-1.27-1.09 1.19-3.63 3.02-5 1.27zm89.81-1.4c-1-2.42 1.22 0.55 0 0zm-67.52-1.51c-0.72-2.45 1.24 1.37 0 0zm-12.92-0.71c-1.44-4.7 4.03-3.51 0 0zm14.82 0.27c0.42-0.69 0.5 0.37 0 0zm65.3-0.42c-0.27-1.12 1.32 0.6 0 0zm-88.6-1.8c-0.06-1.11 0.72 0.55 0 0zm6.29-0.2c-0.02-0.93 0.83 0.6 0 0zm-2.15-1.89c0.33-1.49 0.6 0.72 0 0zm4.89 0.04c2.54-5.1 5.68 0.96 0 0zm-3-0.08c-3.16-2.63 2.31-1.71 0 0zm31.17-1.87c-3.44-3.94 6.44-3 8.6-4.59 2.59-1.53 11.69 1.56 9.37 2.16-5.92-3.69-11.59 3.28-17.24 1.47l-0.41 0.35zm1.67-0.05c0.44-1.83 0.38 0.81 0 0zm-7.25-1.82c-6.42-1.56 5.03-7.49 2.21-2.63-1.2 0.38-0.45 3.42-2.21 2.63zm2.55-0.72c-1.64-2.07 3.31 0.96 0 0zm-27.42-0.8c-0.54-6.59 3.3-3.12 0 0zm-1.19-1.83c0.78-1 0.88 1.24 0 0zm-1.54-0.45c0.99-1.04 1.66 1.29 0 0zm1.06-0.73c0.71-0.8 0.71 0.8 0 0zm-1.9-0.47c0.25-0.9 0.6 0.7 0 0zm-1.43-0.17c0.36-0.68 0.36 0.68 0 0zm1.9-1.57c1.04-1.47 0.8 1.67 0 0zm1.78-0.43c-2.83-2.63 2.27 0.93 0 0zm-4.94-0.13c-1.08-3.54 5.63-10.24 4.11-3.1-0.8 1.64-2.65 2.23-4.11 3.1zm1.96-2.99c-0.44-1.76-0.63 2.17 0 0zm-0.71 2.8c0.57-0.52 0.3 1.08 0 0zm1.9-0.69c0.36-0.68 0.36 0.68 0 0zm-0.95-0.31c0.14-1.18 0.57 0.87 0 0zm38.92-0.67c-0.98-1.43 1.99 0.9 0 0zm0.9-0.16c1.78-2.23-3.81-3.54 0.58-3.99 0.94-4.66 10.38-4.24 8.29-9.63 3.15-3.34-6.92 2.98-3.23-2.73 1.98-2.98-3.16 2.24-4.19-1.45-4.5-0.34-2.68-3.36 0.1-1.18 3.3-1.42 5.03-1.59 7.14-0.7 6.76-5.54-3.71-6.98-7.27-4.63 1.46-1.41-5.42-0.56-1.41-2.48 5.22 1.24 10.1-5.95 14.92-1.49 4.9-2.04 8.41-10.29 14.61-4.84 3.85 3.23 6.12 9.35 6.4 13.28-3.2-2.46-8.1-3.79-11.21-1.22-2.31-3.62-10.61-1.77-11.94-2.39-3.82 3.79 2.78 0.24 2.36 5.27-0.95 3.46-1.28 13.78-5.69 11.97-1.84-2.44-6.8 6.28-9.48 6.2zm3.13-5.52c-0.23-0.62-0.32 0.66 0 0zm8.96-9.5c-0.61-1.13-0.68 1.21 0 0zm2.62-0.17c-0.49-0.74-0.41 0.7 0 0zm-7.72-0.95c-0.39-1.11-0.33 1.71 0 0zm3.6 0.4c-0.3-0.66-0.58 0.47 0 0zm-1.3-0.53c-0.67-0.51-0.31 0.94 0 0zm0.51-1.13c-0.39-1.26-1.28 1.13 0 0zm3.57-9e-3c-0.41-0.7-0.49 0.74 0 0zm-8.14-0.26c0.14-3.83-3.57 0.19 0 0zm7.37-0.24c-0.43 0.12 0.54 0.77 0 0zm-0.52-0.74c0.03-1.29-0.96 0.46 0 0zm-1.59-1.42c0.4-2.2-2 0.6 0 0zm11.73-5.35c0.81-1.23-1.89 0.93 0 0zm-13.45-0.4c-0.25-1.62-1.5 0.85 0 0zm16.34-1.18c-0.29-1.28-1.24 1.71 0 0zm-7.74-0.71c0.99-1.35-1.72 1.31 0 0zm-55.29 27.59c0.41-0.7 0.49 0.74 0 0zm49.53-1.9c1.27-1.94 1.7 2.18 0 0zm-48.66-0.47c-0.03-0.83 0.54 0.56 0 0zm-31.49-1.94c-5.24-2.13-2.04-9.99-6.32-12.75 1.19-4.25 11.46-4.72 4.81 0.29-3.04 3.74 4.92 5.72 4.3 5.73 4.38-3.65 9.21-5.82 13.32-9.78 2.48 0.61 5-9.79 6.52-5.39-3.45 6.84-10.36 10.69-15.93 15.44 7.19 2.76-7.29 0.66-6.69 6.45zm3.11-6c-0.49-0.74-0.41 0.7 0 0zm11.1-7.92c-0.23-0.62-0.32 0.66 0 0zm29.39 13.78c1.77-1.13 0.35-5.63-0.83-1.98-4.06-6.02 2.95-11.49 4.13-17.08 4.58-0.6-0.3 6.2 1.15 1.24-3.39 3.07-1.34 8.71-3.89 12.64 3.12-0.78 1.1 4.98-0.56 5.18zm0.25-11.57c-0.55-0.27-0.39-0.19 0 0zm-13.34 11c-4.42-2.38 3.81-8.18 1.49-1.92-0.28 0.55-0.41 2.14-1.49 1.92zm0.57-4.65c-0.23-0.62-0.32 0.66 0 0zm12.05 3.91c0.43-1.71 0.65 0.99 0 0zm-1.61-2.11c0.75-0.52 0.13 0.42 0 0zm20.27 8e-3c-0.33-1.45 1.58 0.98 0 0zm5.36-0.38c0.33-1.52 0.87 0.9 0 0zm-46.12-0.95c0.6-0.81 0.47 0.74 0 0zm43.67-0.93c0.38-0.99 0.7 0.51 0 0zm1.11-0.49c0.32-0.66 0.23 0.62 0 0zm-33.41-0.19c0.87-1.87 1.44 0.92 0 0zm32.14 0.04c-2.53-1.24 1.22-0.55 0 0zm-30.43-0.48c0.17-0.9 0.54 0.63 0 0zm34.18-0.25c0.32-0.89 0.32 0.89 0 0zm-46.2-0.5c3.53-4.44 6.21-11.88 8.73-15.32-1.1 5.07-3.58 13.67-8.73 15.32zm8.13-13.53c-0.23-0.62-0.32 0.66 0 0zm28.93 13.56c0.67-1.14 1.09 0.43 0 0zm-26.59-0.26c-1.41-2.15 2.59 0.68 0 0zm37-0.88c-0.31-1.06 1.08 0.38 0 0zm-44.64-0.41c0.1-1.67 0.6 0.69 0 0zm46.79-0.37c0.34-0.99 0.43 0.66 0 0zm-6.05-0.39c0.36-0.68 0.36 0.68 0 0zm3.32-0.05c-1.71-1.99 1.14-0.75 0 0zm-3.33-0.73c-1.42-3.29 7.07-1.99 2.28-1.22l-1.13 0.82zm-4.12-0.33c0.87-0.87 0.73 0.81 0 0zm-73.47-2.08c-2.5-2.42 8.89-3.4 1.27-2.95-7.44 1.56-5.38-13.97-0.73-6.38-1.39 8.59 10.13 1.13 11.78 2.24-2.21 4.38-7.57 6.9-12.32 7.08zm-0.04-4.64c1.06-2.32-3.03 1.36 0 0zm76.88 4.24c-1.25-1.47 2.47 0.75 0 0zm-21.91-1.2c0.12-1.7 1.33 1.11 0 0zm27.49-0.92c0.16-1.55 2 0.68 0 0zm-1.5-0.28c-1.34-3.49 2.94-0.5 0 0zm-24.88-0.23c0.07-2.02 1.11 0.87 0 0zm22.99-0.27c-0.1-1.76 2.08 1.62 0 0zm5.81 0.05c-0.22-0.98 0.86 0.41 0 0zm-1.38-0.29c-5.76-3.69 4.11-0.02 0 0zm13.75 0.13c-1.91-2 1.76-0.14 0 0zm4.16-0.04c0.59-1.64 0.85 0.8 0 0zm-11.96-0.48c0.58-0.47 0.28 0.67 0 0zm20.37 1e-3c0.49-0.74 0.41 0.7 0 0zm-81.87-0.63c0.29-2.88 3.06 0.66 0 0zm56.43 0c-0.02-2.61 1.04 0.99 0 0zm-28.39-0.1c1.24-1.64 2.21 0.84 0 0zm32.85 0.14c0.05-1.83 2.11 0.07 0 0zm-9.3-0.25c0.89-0.66 0.87 0.71 0 0zm-16.21-0.32c1.7-1.53 6e-3 1.48 0 0zm12.36-0.14c0.8-0.76-0.08 0.5 0 0zm12.33 0.02c0.68-0.82 0.58 0.77 0 0zm-14.48-0.41c0.33-1.49 0.6 0.72 0 0zm13.24-0.02c-0.32-1.03 0.92-0.14 0 0zm-6.99-0.46c-0.37-1.19 1.02 0.5 0 0zm-54.37-0.21c0.34-1.64 1.17 0.98 0 0zm58.95-0.34c-0.06-1.43 1.45 0.72 0 0zm-57.58-0.19c0.31-0.94 0.67 0.51 0 0zm31.5-1.22c1.21-5.92 4.37 0.27 0 0zm1.58-1.6c-0.36-0.67-0.36 0.68 0 0zm-31.86 1.11c0.36-0.68 0.36 0.68 0 0zm7.21-2.85c1.09-1.15-0.41 1.08 0 0zm8-0.62c0.32-1.62 0.62 1 0 0zm14.9-0.17c0.54-0.75 0.54 0.75 0 0zm-4.16-0.56c0.26-1.92 0.83 1.35 0 0zm2.46 0.29c-0.37-1.15 2.1 1.14 0 0zm45.29-3.3c0.55-1.06 0.48 0.9 0 0zm-94.95-1.25c0.2-4.61 9.09-0.46 2.58-0.09l-1.29 0.15zm-7.32-1.16c-1.95-1.56 0.32-1.52 0.45-0.03zm29.03-2.42c0.45-0.66 0.6 0.44 0 0zm2.85 5e-3c1-1.07 0.32 0.68 0 0zm0.24-0.79c-3.84-0.37 1.7-1.72 0 0zm-4.78-0.4c-4.66-3.44 1.04-7.46-3.73-9.83-2.41-1.63-5.83-10.55-1.31-5.04 2.92 4.1 7.97 8.38 8.71 13.07-1.25 0.55-3.11 0.2-3.67 1.8zm-23-1.19c-4.31-6.82 10.94-6.91 5.7-1.68-2.4 0.34-4.37-0.1-5.7 1.68zm86.34-0.48c0.36-0.68 0.36 0.68 0 0zm-91.93-2.52c0.05-0.82 0.64 0.34 0 0zm25.36-1.45c0.02-1.79 2.07-0.1 0 0zm70.96-0.38c-0.18-1.25 0.85 0.7 0 0zm-72.84-0.79c-2.84-1.75-9.03-8.07-2.03-5.21 1.78 0.46 3.4 3.84 2.03 5.21zm-23.56-0.11c0.1-1.34 1.17 1.3 0 0zm16.1 0.05c-0.09-1.19 0.88 0.45 0 0zm-2.6-0.92c-0.03-1.39 1.19 0.99 0 0zm3.63-0.35c-3.46-2.88 0.99-2.12 1.12 0.17zm-1.57 0.18c-0.41-0.86 0.98 0.22 0 0zm-16.43-2.04c-0.39-2 1.16 1.36 0 0zm6.54-0.58c-5.16-6.76 6.11 0.5 0 0zm-4.39-0.75c0.41-0.7 0.49 0.74 0 0z';
    string constant SHADING_LAYER = 'm212 297c0.42-1.92 0.91 0.55 0 0zm12.34-6.82c-5.07-6.36-9.12-13.52-14.44-19.6-4.23-4.57-8.35-9.62-9.98-15.76 6.75 4.89 10.54 12.71 16.62 18.33 4.48 4.72 10.62 10.64 8.42 17.74-0.24 0.52-1.09-0.46-0.61-0.72zm-6.05-1.24c-0.95-3.87 0.58-5 0 0zm-93.59-13.86c0.27-0.69-0.03 1.08 0 0zm4.4-12.24c-0.92-5.21-13.28-8.76-10.93-11.9 5.79 1.39 9.63 6.28 10.93 11.9zm-5.7-9.07c-0.36-0.67-0.36 0.68 0 0zm21.74 6.39c0.43-1.44 0.7 0.69 0 0zm33.16-11.78c5.8-5.72 0.49 3 0 0zm-0.7-3.8e-4c0.32-0.66 0.23 0.62 0 0zm13.6-0.87c-4.76 0.54 1.77-2.07 0 0zm-7.9-1.48c0.12-0.9 0.78 0.17 0 0zm1.34-0.36c-0.15-1.67 1.25 1.11 0 0zm-75.25-12.29c-4.09-2.48-3.27-10.13-5.09-12.83 1.86-2.69 8.68-2.72 3.87 1.04-3.34 5.64 7.14 8.78 7.97 7.08-3.38-0.51-4.37 3.49-6.74 4.71zm3.64-5.72c0.16-3.67 7.38-3.03 2.14-0.84l-1 0.58zm-1.37-0.83c0.73-2.52 1.5 0.74 0 0zm7.61-2.2c0.52-1.82 2.26 5e-3 0 0zm2.13-1.63c0.32-0.66 0.23 0.62 0 0zm1.19-0.93c0.05-0.82 0.64 0.34 0 0zm-24.65-1.27c-1.23-2.8 6.61-1.36 4.49-4.84 2.86-1.46 11.5-4.36 5.19 0.71-2.82 2.06-5.91 4.76-9.68 4.13zm-0.75-3c-5.03-1.82-3.37-12.83 1.64-6.53 0.24 2.55-3.75 6.82 1.54 4.82 2.4 0.69-2.67 2.66-3.19 1.72zm101.56-5.1c2.24-3.98 5.42-0.28 0 0zm4.02-2.08c-7.66-5.54 9.16-5.46 2.74-1.66-1.44-0.67-1.06 2.59-2.74 1.66zm-3.43-1.27c0.62-1.36 0.71 0.75 0 0zm-93.6-5.9c2.77-5.29 6.33 2.1 0 0zm-8.89-1.66c-0.43-0.94 0.61 0.22 0 0zm27.27-4.71c-1.02-4.31 2.99-1.91 0 0zm-5.42-6.79c-1.4-2.38 2.09 0.53 0 0zm4.24-0.5c-3.29-2.85 0.46-3.38 0 0zm-1.83-3.16c-0.88-1.15 1.03 0.75 0 0z';

    string constant OPEN_PATH = '<path d="';
    string constant FILL_PATH = '" fill="#';
    string constant CLOSE_PATH = '"/>';

    bytes12 constant PLTE_0 = hex'f0e4d1e4cca9ca9962a96e38';
    bytes12 constant PLTE_1 = hex'f0ded1e4bda9ca8362a73e10';
    bytes12 constant PLTE_2 = hex'd9d3cfcbc4b2bba99299846b';
    bytes12 constant PLTE_3 = hex'dfdddbece7d8cdc5bceae0d4';
    bytes12 constant PLTE_4 = hex'f0ecd1f0ecd1cab662a98638';
    bytes12 constant PLTE_5 = hex'dfdddba8a28d7b5b36543921';
    bytes12 constant PLTE_6 = hex'cfd6d9b2c0cb819ab36b8c99';
    bytes12 constant PLTE_7 = hex'd1d9cfb7cbb281b3952d7155';
    bytes12 constant PLTE_8 = hex'd2cfd9bbb2cb9581b38b6b99';
    bytes12 constant PLTE_9 = hex'd9d9cfcbcab2b2b38199936b';

    function getLayer(string memory layer, string memory color) private pure returns (string memory){
        return string.concat(
            OPEN_PATH,
            layer,
            FILL_PATH,
            color,
            CLOSE_PATH
        );
    }

    function getPLTE(uint8 index) public pure returns (string[4] memory plte) {

        require(index < 10, "DOG: INVALID PLTE");

        bytes12 fullPLTE;

        if(index == 0) {
            fullPLTE = PLTE_0;
        } else if(index == 1){
            fullPLTE = PLTE_1;
        } else if(index == 2){
            fullPLTE = PLTE_2;
        } else if(index == 3){
            fullPLTE = PLTE_3;
        } else if(index == 4){
            fullPLTE = PLTE_4;
        } else if(index == 5){
            fullPLTE = PLTE_5;
        } else if(index == 6){
            fullPLTE = PLTE_6;
        } else if(index == 7){
            fullPLTE = PLTE_7;
        } else if(index == 8){
            fullPLTE = PLTE_8;
        } else {
            fullPLTE = PLTE_9;
        }

        plte[0] = LibString.toHexStringNoPrefix(uint256(uint24(bytes3(fullPLTE))),3);
        plte[1] = LibString.toHexStringNoPrefix(uint256(uint24(bytes3(fullPLTE << 24))),3);
        plte[2] = LibString.toHexStringNoPrefix(uint256(uint24(bytes3(fullPLTE << 48))),3);
        plte[3] = LibString.toHexStringNoPrefix(uint256(uint24(bytes3(fullPLTE << 72))),3);
    }

    function getColorName(uint8 colourIdx) public pure returns (string memory) {

        if(colourIdx == 0) {
            return "tan";
        } else if(colourIdx == 1){
            return "red";
        } else if(colourIdx == 2){
            return "gray";
        } else if(colourIdx == 3){
            return "snowy";
        } else if(colourIdx == 4){
            return "golden";
        } else if(colourIdx == 5){
            return "brown";
        } else if(colourIdx == 6){
            return "ice age";
        } else if(colourIdx == 7){
            return "canto green";
        } else if(colourIdx == 8){
            return "based purple";
        } else {
            return "ghost";
        }

    }

    function fetchDog(uint8 colourIdx) public pure returns (string memory) {

        string[4] memory plte = getPLTE(colourIdx);

        return string.concat(
            getLayer(LAYER_0,plte[0]),
            getLayer(LAYER_1,plte[1]),
            getLayer(LAYER_2,plte[2]),
            getLayer(LAYER_3,plte[3]),
            getLayer(SHADING_LAYER,"504c43") //this one is fixed
        );

    }

    function fetchDog(uint8 colourIdx, string memory chewToy) public pure returns (string memory) {

        string[4] memory plte = getPLTE(colourIdx);

        string memory grouping = string.concat(
            '<text x="90" y="300" font-size="18">',
            chewToy,
            '</text>'
        );

        return string.concat(
            grouping,
            getLayer(LAYER_0,plte[0]),
            getLayer(LAYER_1,plte[1]),
            getLayer(LAYER_2,plte[2]),
            getLayer(LAYER_3,plte[3]),
            getLayer(SHADING_LAYER,"504c43") //this one is fixed
        );

    }

}

//this Library helps spruce up your dog
library libDogEffects{

    string constant G_WORD_BUBBLE_1 ='<g id="words"><ellipse cx="50%" cy="44%" rx="90" ry="25" fill="white"></ellipse><circle cx="20%" cy="48%" r="10" fill="white"/><circle cx="20%" cy="56%" r="8" fill="white"/><circle cx="23%" cy="61%" r="5" fill="white"/><text x="50%" y="45%" fill="';
    string constant G_WORD_BUBBLE_2 ='" text-anchor="middle" class="words">';
    string constant G_WORD_BUBBLE_3 = '</text></g>';

    function getWordBubble(string memory text, string memory textColor) internal pure returns (string memory) {
        return string.concat(
            G_WORD_BUBBLE_1,
            textColor,
            G_WORD_BUBBLE_2,
            text,
            G_WORD_BUBBLE_3
        );
    }

}

interface ICInu {
    function totalSupply() external view returns (uint256);
}

interface IAmpliceGhoul {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface INonFungibleDog {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function getTimesBurnt(uint256 tokenId) external view returns (uint256);
    function getCInuBurnt(uint256 tokenId) external view returns (uint256);

}

interface IDefs {
    function buildDefs(uint8 eyeAttr, bool amplice) external pure returns (string memory);
    function getAttributePlacements(uint8 eyeAttr, bool amplice) external view returns (string memory useStr);
    function getBackground(string memory _borderLvl, string memory _noiseColor) external pure returns (string memory);
    function createPNGs(uint256 count) external pure returns (string memory pngRunners);
}

interface IDog {
    function fetchDog(uint8 colourIdx)  external pure returns (string memory);
    function fetchDog(uint8 colourIdx, string memory chewToy)  external pure returns (string memory);
    function getColorName(uint8 colourIdx) external pure returns (string memory);
}

contract dogURI{
    using LibString for uint256;

    string public DNAJuice;

    IAmpliceGhoul public immutable ampliceGhoul;// = IAmpliceGhoul(0x81996BD9761467202c34141B63B3A7F50D387B6a);
    INonFungibleDog public immutable nonFungibleDog;// = INonFungibleDog(0x81996BD9761467202c34141B63B3A7F50D387B6a);
    IDefs public immutable defs;
    IDog public immutable dog;

    struct DOG_ATTR {
        uint8 bg_color;
        uint8 dog_color;
        uint8 words_text;
        uint8 words_color;
        uint8 eyes;
        uint8 filters;
        uint8 chewToys;
        uint8 animation;
        uint8 noise_color;
        uint8 goodBoy_text;
        bool amplice;
    }

    struct STATS_DATA {
        uint256 burnTimesCount;
        uint256 burnAmtCount;
    }

    struct IMAGE_DATA {
        string defs;
        string bgElement;
        string dogElement;
    }

    struct SVG_STATE {
        uint256 id;
        DOG_ATTR attr;
        STATS_DATA stats;
        IMAGE_DATA img;
        string jsonAttr;
    }

    string constant SVG_HEADER = '<svg version="1.1" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><mask id="screen"><rect width="310" height="310" x="20" y="20" rx="20" fill="white" /></mask>';
    string constant SVG_FOOTER = '</svg>';

    // first 8 normal, 9th for missing dogs
    string[] private goodBoy = [
        "Top Dog",
        "A very good dog indeed",
        "Such a good pup",
        "Man's best friend",
        "Cheemsburbger",
        "Thank You Based Dog",
        "They're good dogs, Brent",
        "13/10",
        "Umm hey, where's my dog?"
    ];

    string[] private words = [
        "such wow",
        "very moon",
        "good boi", 
        "many burn",
        "wen",
        "protec",
        "attac",
        "so hodl",
        "muh canto",
        "I havs marketing proposal",
        "bonk",
        "devs do something",
        "no rug pls"
        "@raydaybot",
        "CANTO INU",
        "RIP Miraj"
    ];

    // noise uses full set, words only use first 5
    string[] private colors = [
        "blue",
        "green",
        "orange",
        "blue",
        "purple",
        "gray",
        "yellow",
        "white"
    ];

    string[] private borderLvlColors = [
            "Gold",
            "Silver",
            "#CD7F32",
            "#7FFFD4",
            "#F5F5F5"        
    ];

    //default values, need to be able to set this
    uint256[] private borderLvlAmts = [
        16_900_000_000_000 * 10**18,
        8_450_000_000_000 * 10**18,
        4_225_000_000_000 * 10**18,
        845_000_000_000 * 10**18
    ];

    string[] private chewToys = [
        unicode"🦴",
        unicode"🦴",
        unicode"🍖",
        unicode"🚀",
        unicode"🐕",
        unicode"🐈",
        unicode"🦶",
        unicode"☠️",
        unicode"🤝",
        unicode"🧟",
        unicode"🫂",
        unicode"🥓",
        unicode"🍔",
        unicode"🗾",
        unicode"🌙",
        unicode"🔥",
        unicode"📫",
        unicode"📈",
        unicode"🛹",
        unicode"🏏",
        unicode"💣"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function bg_colour_idx(uint256 _burn) internal view returns (uint8) {
        if (_burn > borderLvlAmts[0]) {
            return 0;
        } else if (_burn > borderLvlAmts[1]) {
            return 1;
        } else if (_burn > borderLvlAmts[2]) {
            return 2;
        } else if (_burn > borderLvlAmts[3]) {
            return 3;
        } else {
            return 4;
        }
    }

    function attributify(uint256 _id, bool _amplice) internal view returns (DOG_ATTR memory _attr) {
        
        bytes32 dogDna = bytes32(random(string.concat(_id.toString(),DNAJuice)));
         /*//dogDNA is a tightly packed array of bytes used to assign NFT attributes, info arranged as follows:
            // [0-1] - missing dog
            // [2] - dog color
            // [3] - words text
            // [4] - words color
            // [5] - eyes
            // [6] - filters
            // [7] - playToy
            // [8] - animation/transformation
            // [9] - screenNoise
            // [10] - goodBoy text
            */
        

        //first check if this is an ultra rare, missing dog
        bool _missing = uint16((bytes2(dogDna[0])) | bytes2(dogDna[1])>>8)%69 == 0;

        _attr = DOG_ATTR({
            bg_color:       0,
            dog_color:      uint8(uint8(dogDna[2]) % 10),
            words_text:     uint8(dogDna[3]),
            words_color:    uint8(dogDna[4]),
            eyes:           uint8(dogDna[5]),
            filters:        uint8(dogDna[6]),
            chewToys:       uint8(dogDna[7]),
            animation:      uint8(dogDna[8]),
            noise_color:    uint8(uint8(dogDna[9]) % (colors.length - 2)),
            goodBoy_text:   _missing ? uint8(8) : uint8(uint8(dogDna[10]) % (goodBoy.length-1)),
            amplice:        _amplice
        });
    }

    function word_attr(DOG_ATTR memory _attr) internal view {
        if(_attr.words_text > 127) {
            _attr.words_text %= uint8(words.length);
            _attr.words_color %= uint8((colors.length-2));
        } else {
            _attr.words_text = 255;
            _attr.words_color = 255;
        }
    }

    function dog_attr(DOG_ATTR memory _attr) internal pure {
        _attr.eyes > 127 ? _attr.eyes %= 4 : _attr.eyes = 255;
        _attr.filters > 127 ? _attr.filters %= 6 : _attr.filters = 255;
        _attr.chewToys > 64 ? _attr.chewToys %= 18 : _attr.chewToys = 255;
        _attr.animation > 127 ? _attr.animation %= 10 : _attr.animation = 255;
    }   

    function attributes(uint256 id, bool amplice) internal view returns (DOG_ATTR memory attr) {

        attr = attributify(id, amplice);

        //update attributes for rarity
        word_attr(attr);
        dog_attr(attr);

    }

    function initializeState(uint256 id) internal view returns (SVG_STATE memory s) {

        STATS_DATA memory tokenInfo = STATS_DATA(
            nonFungibleDog.getTimesBurnt(id),
            nonFungibleDog.getCInuBurnt(id)
        );

        address dogOwner = nonFungibleDog.ownerOf(id);

        DOG_ATTR memory attr = attributes(id, ampliceGhoul.balanceOf(dogOwner) > 0);
        attr.bg_color = bg_colour_idx(tokenInfo.burnAmtCount);

        IMAGE_DATA memory img;

        s = SVG_STATE(
            id,
            attr,
            tokenInfo,
            img,
            ""
        );
    }

    function createStats(SVG_STATE memory s) internal view returns (string memory statsStr) {

        statsStr = string.concat(
            '<g class="stats"><text x="33" y="40">NFT ID: ',
            s.id.toString(),
            '</text><text x="33" y="55">cINU Burnt: ',
            (s.stats.burnAmtCount/10**18).toString(),
            '</text><text x="33" y="70">Good dog? ',
            goodBoy[s.attr.goodBoy_text],
            '</text></g>'
        );

        return statsStr;
    }

    function writeDefs(SVG_STATE memory s) internal view {
        s.img.defs = defs.buildDefs(s.attr.eyes, s.attr.amplice);

    }

    function writeBG(SVG_STATE memory s) internal view {

        s.img.bgElement = string.concat(
            defs.getBackground(borderLvlColors[s.attr.bg_color], colors[s.attr.noise_color]),
            defs.createPNGs(s.stats.burnTimesCount),
            createStats(s)
        );

    }

    function writeDog(SVG_STATE memory s) internal view {
        string memory dogEl = '<g id="dog">';

        if (s.attr.chewToys == 255) {
            dogEl = string.concat(
                dogEl,
                dog.fetchDog(s.attr.dog_color)
            );
        } else {
            dogEl = string.concat(
                dogEl,
                dog.fetchDog(s.attr.dog_color,chewToys[s.attr.chewToys])
            );
        }

        if(s.attr.words_text != 255) {
            dogEl = string.concat(
                dogEl,
                libDogEffects.getWordBubble(words[s.attr.words_text],colors[s.attr.words_color])
            );
        }

        dogEl = string.concat(
            dogEl,
            defs.getAttributePlacements(s.attr.eyes, s.attr.amplice),
            '</g>'
        );

        s.img.dogElement = dogEl;

    }

    
    function returnImg(SVG_STATE memory s) internal view returns (string memory) {
                
        writeDefs(s);

        writeBG(s);

        if(s.attr.goodBoy_text != 8) {
            writeDog(s);
        } else {
            defs.getAttributePlacements(255, s.attr.amplice);
        }
        

        return string.concat(
            s.img.defs,
            s.img.bgElement,
            s.img.dogElement
        );

    }

    function uri(uint256 id) external view returns (string memory) {
        // initialize state elements
        SVG_STATE memory s = initializeState(id);

        string memory img = returnImg(s);
        
        bytes memory json = bytes(
            string.concat(
                '{"name": "Non-Fungible Dog #', LibString.toString(id), '", "description": "Each dog is special, and some have more power than others. Love your pup the way you want.", "image": "data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            SVG_HEADER,
                            img,
                            SVG_FOOTER
                        )
                    )
                ),
                '"}'
            )
        );

        return string.concat(
            'data:application/json;base64,', 
            Base64.encode(json)
        );
    }

    constructor(
        address _defs,
        address _dog,
        address _nft,
        address _amplice
        ){
            defs = IDefs(_defs);
            dog = IDog(_dog);
            nonFungibleDog = INonFungibleDog(_nft);
            ampliceGhoul = IAmpliceGhoul(_amplice);

            DNAJuice = block.timestamp.toString();
        }  

}
