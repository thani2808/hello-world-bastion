package hello_world_bastion;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloBastionController {
	
  @GetMapping("/")
  public String hello() {
    return "Welcome to Hello, World! Bastion first project";
  }
}