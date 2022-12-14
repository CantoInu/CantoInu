// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import {LibString} from "../utils/utils.sol";

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