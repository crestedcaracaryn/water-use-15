num_pies <- 2000

x_rng <- c(0, 150)
y_rng <- c(0, 180)
view_coords <- c(300, 200)
set.seed(99)
x_coords <- runif(n = num_pies, min = x_rng[1], max = x_rng[2])
y_coords <- runif(n = num_pies, min = y_rng[1], max = y_rng[2])

r_0 <- rlnorm(num_pies, 0, .6)/2
r_1 <- rlnorm(num_pies, 0, .6)/2

library(xml2)
library(dplyr)
m = xml_new_document() %>% 
  xml_add_child('html', prefix="og: http://ogp.me/ns#", lang="en") 
m %>% xml_add_child('head') %>% 
  xml_add_child('script', src="https://d3js.org/d3.v4.min.js", charset="utf-8") %>% 
  xml2::xml_add_child('dummy') # trailing solidus hack?
bd <- m %>% xml_add_child('body')
bd %>% xml_add_child('style',
                     ".therm {
			fill:#b2e7e2;
      stroke:#b2e7e2;
      stroke-width:0.3;
			fill-opacity:0.5;
                     }
    .dot {
                     stroke-width:0.3;
                     fill-opacity:0.5;
                     }
		.irr {
			fill:red;
      stroke:red;
      stroke-width:0.3;
			fill-opacity:0.8;
		}")
svg <- bd %>% 
  xml_add_child('svg', xmlns="http://www.w3.org/2000/svg", 
                "xmlns:xlink"="http://www.w3.org/1999/xlink", version="1.1", preserveAspectRatio="xMinYMin meet", 
                viewBox=sprintf("0 0 %s %s", view_coords[1], view_coords[2]))

path_template <- "M%1.1f %1.1f a %1.1f %1.1f 0 1 1 0 0.01 " #x start, y-start, radius, radius

path_from <- c()
path_mid <- c()
path_to <- c()
for (i in 1:num_pies){
  path_from <- paste0(path_from, sprintf(path_template, x_coords[i]-r_0[i], y_coords[i], r_0[i], r_0[i]))
  path_mid <- paste0(path_mid, sprintf(path_template, x_coords[i]-0.1, y_coords[i], 0.1, mean(c(r_0[i],r_1[i]))))
  path_to <- paste0(path_to, sprintf(path_template, x_coords[i]-r_1[i], y_coords[i], r_1[i], r_1[i]))
}

circle_data <- data.frame('cx'=x_coords, 'cy'=y_coords, 'scale1'=r_0, 'scale2' = r_1) %>% 
  jsonlite::toJSON()

bd %>% xml_add_child('script', 
                     sprintf("var data = [{therm:'%s', mid:'%s', end:'%s'}];
                     var circles = %s;
		                 var aniDur = 1000;
                     
                     var svg = d3.selectAll('svg')
                     svg.append('rect')
                     .attr('x',55)
                     .attr('y',180)
                     .attr('height',10)
                     .attr('width',40)
                     .style('fill','purple')
                     .on('click',flipPath);
                     svg.append('text')
                      .attr('text-anchor','middle')
                      .style('fill','white')
                      .text('circles as path')
                      .attr('transform','translate(75,188)scale(0.4)')
                      .on('click',flipPath);

                    svg.append('rect')
                     .attr('x',203)
                             .attr('y',180)
                             .attr('height',10)
                             .attr('width',44)
                             .style('fill','purple')
                             .on('click',flipCircles);
                    svg.append('text')
                      .attr('text-anchor','middle')
                             .style('fill','white')
                             .text('circles as circle')
                             .attr('transform','translate(225,188)scale(0.4)')
                             .on('click',flipCircles);                     
                    var defs = svg.append('defs');
                     defs.selectAll('path')
                     .data(data)
                     .enter()
                     .append('path')
                     .classed('dot',true)
                     .attr('d', function(d){
                      return d.therm;
                     })
                     .style('fill','#b2e7e2')
                     .style('stroke','#b2e7e2')
                     .attr('id','path-circle');

                    svg.append('use')
                      .attr('xlink:href','#path-circle')
                      .attr('id','circle');

                     var cg = defs.append('g')
                      .attr('id','circle-circle')
                      .attr('transform','translate(150,0)');
                    cg.selectAll('circle')
                     .data(circles)
                             .enter()
                             .append('circle')
                             .attr('cx', function(d){
                                return d.cx;
                             })
                             .attr('cy', function(d){
                                return d.cy;
                             })
                            .attr('r', function(d){
                                return d.scale1;
                             })
                             .attr('class','dot')
                              .style('fill','#b2e7e2')
                             .style('stroke','#b2e7e2');
                     svg.append('use')
                      .attr('xlink:href','#circle-circle')
                      .attr('id','circles');
                             
                     function flipPath(){
                    d3.selectAll('#path-circle')
                       .transition()
                             .ease(d3.easeLinear)
                             .duration(aniDur)
                             .attr('d', function(d){
                             return d.end;
                             })
                             .duration(aniDur).style('fill','red').style('stroke','red');
                     }
                             function flipCircles(){
                     d3.selectAll('circle')
                             d3.selectAll('circle')
                             .transition()
                             .ease(d3.easeLinear)
                             .duration(aniDur)
                             .attr('r', function(d){
                                return d.scale2;
                             })
                              .style('fill','red').style('stroke','red');
                             }", path_from, path_mid, path_to, circle_data)) 
write_xml(m, 'scripts/sandbox/test.html')