// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

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