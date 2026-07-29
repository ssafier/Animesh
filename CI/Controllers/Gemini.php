<?php

namespace App\Controllers;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\I18n\Time;
use Psr\Log\LoggerInterface;

use App\Models\Characters;
use App\Models\Visitors;
use App\Models\ChatLogs;
    
use App\Entities\Visitor;
use App\Entities\Npc;
use App\Entities\ChatLog;

class Gemini extends BaseController
{
    protected $helpers = ['url'];
    private $visitors;
    private $chats;
    private $animesh;
    
    public function initController(
        RequestInterface $request,
        ResponseInterface $response,
        LoggerInterface $logger) {
        parent::initController($request, $response, $logger);
        $this->visitors = new Visitors();
        $this->chats = new ChatLogs();
        $this->animesh = new Characters();
    }
 
    public function chat() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return $this->response-setJSON(array('status' => 'error', 'type' => 'invalid json'));;
        }
        $result = $this->visitors->where('avi =',$json['avatar'])->findAll();
        if (!$result || count($result) == 0) {
            log_message('error', 'no visitor');
            return;
        }
        $avatar = $result[0];
        $result = $this->animesh->where('animesh =',$json['npc'])->findAll();
        if (!$result || count($result) == 0) {
            log_message('error', 'no character');
            return;
        }
        $npc = $result[0];

        $message     = $this->request->getPost('message');

        // 2. Fetch History & Check for Expiration (30 minute timeout)
        $result = $this->chats->where('avatar =', $avatar->id)->where('animesh =', $npc->id)->findAll();
        $previousInteractionId = null;
        $session = null;
        
        if ($result && count($result) > 0) {
            $session = $result[0];
            $lastUpdated = $session->updated_at;
            $threshold = Time::now()->subMinutes(30);
            if ($lastUpdated < $threshold) { 
                // Session is older than 30 minutes, delete it to start fresh
                $this->chats->where('id =', $session->id)->delete();
                $session = null; // Reset session variable
            } else {
                // Session is active, load the existing history
                $previousInteractionId = $session->interaction_id;
            }
        }

        $apiKey = getenv('GEMINI_API_KEY');
        if (!$apiKey) {
             return $this->response->setBody("Error: API Key not configured.");
        }
        // godaddy is stripping the header below, so pass key this way
        $url    = "https://generativelanguage.googleapis.com/v1beta/interactions?key=" . trim($apiKey);
        $systemInstruction = 
            'Keep your responses concise and punchy.   If the user text is wrapped in astericks (e.g. *punch*), this is a physical action taken against you.  React to the physical action in character.  DO NOT INCLUDE ASTERISKS IN YOUR RESPONSE.\n'.
            $npc->description . '\n ' . $json['avatar-desc'] . '\n' . $json['text'] ;

        // Build the Interactions payload
        $payload = [
            'model' => 'gemini-3.5-flash-lite', // You can update this to gemini-3.6-flash if you have access to it
            'system_instruction' => $systemInstruction,
            'input' => $json['message']
        ];

        // If this is an ongoing conversation, link it to the previous turn
        if ($previousInteractionId) {
            $payload['previous_interaction_id'] = $previousInteractionId;
        }

        // Execute cURL request to Gemini
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER,
                    [`Content-Type: application/json`,
                    `X-goog-api-key:` . $apiKey]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        $response = curl_exec($ch);
        curl_close($ch);

        // 5. Parse Response & Extract Interaction ID
        $newInteractionId = $responseData['id'] ?? null;
        $responseData = json_decode($response, true);
        
        // Note: The raw REST response structure for the text output might be nested depending on the exact steps. 

        $aiReply = null;
        $newInteractionId = $responseData['id'] ?? null;

        // Check if Gemini returned an API error structure
        if (isset($responseData['error'])) {
            // Log the error to CodeIgniter logs (writable/logs) for debugging
            log_message('info', 'Gemini API Error: ' . ($responseData['error']['message'] ?? 'Unknown error'));
            return $this->response->setJSON(array('status' => 'gemini-error', 'error' => ($responseData['error']['message'] ?? 'Unknown error')));        
        } else {
            // Success: extract the text response recursively
            array_walk_recursive($responseData, function($value, $key) use (&$aiReply) {
                if ($key === 'text') $aiReply = $value;
            });

            // Ultimate fallback if no text key was found
            if (!$aiReply) {
                $aiReply = "I have nothing to say right now.";
            }
        }

        // 6. Save the Updated History Back to the Database
        if ($newInteractionId) {
            if ($session) {
                // Update existing record
                $session->interaction_id = $newInteractionId;
                $this->chats->update( $session->id, $session);
            } else {
                $session = new \App\Entities\ChatLog();
                $session->avatar = $avatar->id;
                $session->animesh = $npc->id;
                $session->interaction_id = $newInteractionId;
                $this->chats->insert($session);
            }
        }
        // 7. Output the response for SecondLife
        // LSL's http_response event will catch this exact string
        return $this->response->setJSON(array('status' => 'ok', 'reply' => $aiReply)); //, 'curl' => $response));        
    }        
}
