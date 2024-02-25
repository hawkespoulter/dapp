import { useState, useEffect } from "react";

import PropTypes from "prop-types";

import LogoEffect from "./LogoEffect";
import { useFetchExperienceCompletionQuery } from "../../store/apis/dappApi";

function toCamelCase(text) {
  const textWithoutPunctuation = text.replace(/[^\w\s]/g, ''); // Needed for main street but good to have
  return textWithoutPunctuation.replace(/(?:^\w|[A-Z]|\b\w)/g, function(word, index) {
    return index === 0 ? word.toLowerCase() : word.toUpperCase();
  }).replace(/\s+/g, '');
}

function LogoEffectLogic({ experience, backgroundImageSuffix, overlayImageSuffix}) {
  const [showCompletionAnimation, setShowCompletionAnimation] = useState(false);
  const {data, isLoading} = useFetchExperienceCompletionQuery(experience);
  const [completedParks, setCompletedParks] = useState([]);
  const [newlyCompletedPark, setNewlyCompletedPark] = useState("");

  console.log("master list", completedParks)

  useEffect(() => {

    if (!isLoading) {
      const newCompletedParks = Object.keys(data).filter(park => data[park] === 100);
      console.log("new parks with 100", newCompletedParks)
      const addedPark = newCompletedParks.filter(park => !completedParks.includes(park));

      const removedParks = completedParks.filter(park => !newCompletedParks.includes(park));

      setCompletedParks(prevParks => prevParks.filter(park => !removedParks.includes(park)));
      console.log("new park added to list", addedPark)
      setCompletedParks(prevParks => [...prevParks, ...addedPark]);

      if (addedPark.length > 0) {
        setNewlyCompletedPark(toCamelCase(addedPark[0]));
        setShowCompletionAnimation(true);
        const timeout = setTimeout(() => {
          setShowCompletionAnimation(false);
        }, 6000);
  
        return () => clearTimeout(timeout);
      }
    }
  }, [data]);

  return ( showCompletionAnimation && 
    <LogoEffect className="absolute" backgroundImage={`${newlyCompletedPark}${backgroundImageSuffix}`} overlayImage={`${newlyCompletedPark}${overlayImageSuffix}`} />
  );
}

export default LogoEffectLogic;

LogoEffectLogic.propTypes = {
  experience: PropTypes.string.isRequired,
  backgroundImageSuffix: PropTypes.string.isRequired,
  overlayImageSuffix: PropTypes.string.isRequired,
};