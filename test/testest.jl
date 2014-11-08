using Images
function graythresh(in_img)
    
    g=convert(Array,in_img);
    step=65536;
    
    #get histogram values
    e,counts=hist(g[:],linrange(minfinite(g[:]),maxfinite(g[:]),step))
        
   im_len=length(in_img);
    
    tot_sum=0;
    for t=1:step-1 
        @inbounds tot_sum=tot_sum+t*counts[t];
    end
    
    sumB = 0;
    wB = 0;
    wF = 0;
    varMax = 0;
    threshold = 0;
    for t = 1:step-1
        
        @inbounds wB=wB + counts[t]; #weight background
        
        @inbounds wF=im_len - wB; #weight foreground
        
        @inbounds sumB=sumB+t*counts[t];
        
        @inbounds mB = sumB / wB;            #Mean Background
        @inbounds mF = (tot_sum - sumB) / wF;    # Mean Foreground
        
        @inbounds varBetween = wB * wF * (mB - mF)^2;
        # Check if new maximum found
        if (varBetween > varMax) 
            varMax = varBetween;
            threshold = t;
        end
    end
    return e[threshold]
end
const test = rand(Uint16, 1000,1000)
@time graythresh(test)
@time graythresh(test)
@time graythresh(test)