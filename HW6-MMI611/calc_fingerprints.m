function s = calc_fingerprints(IJ, s, param)

    I = IJ(2:2:end);
    J = IJ(1:2:end);
    
    % Calculate fingerprints
    for i = 1:length(I)
        for j = i+1:length(I)
            % Calculate time and frequency differences
            timeDiff = (J(j) - J(i)) * (param.colTimes(2) - param.colTimes(1));
            freqDiff = I(j) - I(i);
            
            % Time and frequency ranges
            if (timeDiff >= param.timeDiffMin && timeDiff <= param.timeDiffMax && ...
                freqDiff >= param.fIdxDiffMin && freqDiff <= param.fIdxDiffMax)

                hashCode = round(freqDiff * param.fs / param.fIdxDiffMax) * param.timeDiffMax + round(timeDiff);
                
                % Store the fingerprint in the hashMap
                fieldName = ['h' sprintf('%d', hashCode)]; % MATLAB not allowing numbers to be stored

                % Conditional to check if the field name (fingerprint)
                % already exists in the hashmap.
                % If it does, then append the time indices to an existing
                % array in the hashmap.
                % If not, then create a new field with the field name and
                % assign an array with those time indices.
                % And hope to God it works
                if isfield(s.hashMap, fieldName)
                    s.hashMap.(fieldName) = [s.hashMap.(fieldName); param.cumuSamp + J(i), param.cumuSamp + J(j)];
                else
                    s.hashMap.(fieldName) = [param.cumuSamp + J(i), param.cumuSamp + J(j)];
                end
            end
        end
    end
end